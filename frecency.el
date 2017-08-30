;;; frecency.el --- Library for sorting recently accessed items based on frequency and recency -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/frecency.el
;; Version: 0.1-pre
;; Package-Requires: ((emacs "25.1") (a "0.1.0") (dash "2.13.0")
;; Keywords: library

;;; Commentary:

;;

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; Manual

;; Install these required packages:

;; + a
;; + dash

;; Then put this file in your load-path, and put this in your init
;; file:

;; (require 'frecency)

;;;; Usage



;;;; Tips

;; + You can customize settings in the `frecency' group.

;;;; Credits

;; This package is based on the "frecency" algorithm which was
;; (perhaps originally) implemented in Mozilla Firefox, and has since
;; been implemented in other software.  Specifically, this is based on
;; the implementation described here:

;; <https://slack.engineering/a-faster-smarter-quick-switcher-77cbc193cb60>

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

;;;; Requirements

(require 'a)
(require 'dash)

;;;; Variables

(defgroup frecency nil
  "Settings for `frecency'."
  :link '(url-link "http://example.com/frecency.el"))

(defcustom frecency-max-timestamps 10
  "Maximum number of timestamps to record for each item."
  :type 'integer)

;;;; Functions

;;;;; Public

(cl-defun frecency-score (item &key (get-fn #'a-get))
  "Return score of ITEM.
ITEM should be a collection (an alist by default).  If not an
alist, GET-FN should be set accordingly (e.g. `plist-get' for a
plist)."
  (let* ((timestamps (funcall get-fn item :timestamps))
         (num-timestamps (funcall get-fn item :num-timestamps))
         (latest-timestamp (car timestamps))
         (latest-timestamp-score (frecency--score-timestamp latest-timestamp))
         (total-count (funcall get-fn item :total-count)))
    (/ (* total-count latest-timestamp-score)
       num-timestamps)))

(cl-defun frecency-update (item &optional &key (get-fn #'a-get) (set-fn #'a-assoc))
  "Return ITEM with current timestamp added and counts incremented.
ITEM should be a collection (an alist by default).  If not an
alist, GET-FN and SET-FN should be set
accordingly (e.g. `plist-get' and `plist-put' for a plist)."
  (let* ((current-time (float-time (current-time)))
         (timestamps (cons current-time (funcall get-fn item :timestamps)))
         (num-timestamps (length timestamps))
         (total-count (or (funcall get-fn item :total-count) 0)))
    (when (> num-timestamps frecency-max-timestamps)
      (setq timestamps (cl-subseq timestamps 0 frecency-max-timestamps))
      (setq num-timestamps frecency-max-timestamps))
    (--> item
         (funcall set-fn it :timestamps timestamps)
         (funcall set-fn it :num-timestamps num-timestamps)
         (funcall set-fn it :total-count (1+ total-count)))))

;;;;; Private

(defun frecency--score-timestamp (timestamp &optional current-time)
  "Return score for TIMESTAMP depending on current time.
If CURRENT-TIME is given, it is used instead of getting the
current time."
  (let* ((current-time (float-time (or current-time (current-time))))
         (difference (- current-time timestamp)))
    (cond
     ((<= difference 14400) ;; Within past 4 hours
      100)
     ((<= difference 86400) ;; Within last day
      80)
     ((<= difference 259200) ;; Within last 3 days
      60)
     ((<= difference 604800) ;; Within last week
      40)
     ((<= difference 2419200) ;; Within last 4 weeks
      20)
     ((<= difference 7776000) ;; Within last 90 days
      10)
     (t ;; More than 90 days
      0))))

;;;; Footer

(provide 'frecency)

;;; frecency.el ends here
