
    ;; identica-interface.el
    ;; Copyright (C) 2012  Giménez, Christian N.

    ;; This program is free software: you can redistribute it and/or modify
    ;; it under the terms of the GNU General Public License as published by
    ;; the Free Software Foundation, either version 3 of the License, or
    ;; (at your option) any later version.

    ;; This program is distributed in the hope that it will be useful,
    ;; but WITHOUT ANY WARRANTY; without even the implied warranty of
    ;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    ;; GNU General Public License for more details.

    ;; You should have received a copy of the GNU General Public License
    ;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

    ;; Lunes 30 De Julio Del 2012    


;; PURPOSE:
;; ____________________
;;
;; Change interface and make dents visible.
;;
;; ____________________
;;


(defun identica-render-timeline-orig ()
  (with-current-buffer (identica-buffer)
    (let ((point (point))
	  (end (point-max))
          (wrapped (cond (longlines-mode 'longlines-mode)
                         (visual-line-mode 'visual-line-mode)
                         (t nil)))
	  (stripe-entry nil))

      (setq buffer-read-only nil)
      (erase-buffer)
      (when wrapped (funcall wrapped -1))
      (mapc (lambda (status)
              (let ((before-status (point-marker))
                    (blacklisted 'nil)
                    (formatted-status (identica-format-status
                                       status identica-status-format)))
                (mapc (lambda (regex)
                        (when (string-match-p regex formatted-status)
                          (setq blacklisted 't)))
                      identica-blacklist)
                (unless blacklisted
                  (when identica-enable-striping
                    (setq stripe-entry (not stripe-entry)))
                  (insert formatted-status)
                  (when (not wrapped)
                    (fill-region-as-paragraph
                     (save-excursion (beginning-of-line -1) (point)) (point)))
                  (insert-and-inherit "\n")
                  ;; Apply highlight overlays to status
		  (when (or (string-equal (sn-account-username sn-current-account)
					  (assoc-default 'in-reply-to-screen-name status))
                            (string-match
			     (concat "@" (sn-account-username sn-current-account)
				     "\\([^[:word:]_-]\\|$\\)") (assoc-default 'text status)))
		    (merge-text-attribute before-status (point) 'identica-reply-face :background))
                  (when (and identica-enable-highlighting
			     (memq (assoc-default 'id status) identica-highlighted-entries))
		    (merge-text-attribute before-status (point) 'identica-highlight-face :background))
                  (when stripe-entry
		    (merge-text-attribute before-status (point) 'identica-stripe-face :background))
                  (when identica-oldest-first (goto-char (point-min))))))
            identica-timeline-data)
      (when (and identica-image-stack window-system) (clear-image-cache))
      (when wrapped (funcall wrapped 1))
      (setq buffer-read-only t)
      (debug-print (current-buffer))
      (goto-char (+ point (if identica-scroll-mode (- (point-max) end) 0)))
      (identica-set-mode-string nil identica-method (sn-account-server sn-current-account))
      (setf (sn-account-last-timeline-retrieved sn-current-account) identica-method)
      (if transient-mark-mode (deactivate-mark)))))

(defun identica-render-timeline ()
  "Render all the timeline getting all the information from `identica-timeline-data'."
  (dolist (status identica-timeline-data)
    (let ((formated-status (identica-format-status status identica-status-format)))
      (unless (identica-status-is-in-blacklist formated-status)
	(insert formated-status)))))

(defun identica-profile-image (profile-image-url)
  (when (string-match "/\\([^/?]+\\)\\(?:\\?\\|$\\)" profile-image-url)
    (let ((filename (match-string-no-properties 1 profile-image-url))
	  (xfilename (match-string-no-properties 0 profile-image-url)))
      ;; download icons if does not exist
      (unless (file-exists-p (concat identica-tmp-dir filename))
	(if (file-exists-p (concat identica-tmp-dir xfilename))
	    (setq filename xfilename)
	  (setq filename nil)
	  (add-to-list 'identica-image-stack profile-image-url)))
      (when (and identica-icon-mode filename)
	(let ((avatar (create-image (concat identica-tmp-dir filename))))
	  ;; Make sure the avatar is 48 pixels (which it should already be!, but hey...)
	  ;; For offenders, the top left slice of 48 by 48 pixels is displayed
	  ;; TODO: perhaps make this configurable?
	  (insert-image avatar nil nil `(0 0 48 48)))
	nil))))

(defun identica-format-status (status format-str)
  "Create a string with information from STATUS formatted acording to FORMAT-STR. 

*This function only generates the strings, doesn't insert it in any buffer!*"
  (flet ((attr (key)
	       (assoc-default key status)))	 
    (let ((cursor 0)
	  (result ())
	  c
	  found-at)
      (setq cursor 0)
      (setq result '())

      ;; Follow each "%?" element in FORMAT-STR and elaborate a list called "result" in the order given by that format.
      (while (setq found-at (string-match "%\\(C{\\([^}]+\\)}\\|[A-Za-z#@']\\)" format-str cursor))
	(setq c (string-to-char (match-string-no-properties 1 format-str)))
	(if (> found-at cursor)
	    (push (substring format-str cursor found-at) result)
	  "|")
	(setq cursor (match-end 1))

	(case c
	  ((?s)                         ; %s - screen_name
	   (push (attr 'user-screen-name) result))
	  ((?S)                         ; %S - name
	   (push (attr 'user-name) result))
	  ((?i)                         ; %i - profile_image
	   ;;(push (identica-profile-image (attr 'user-profile-image-url)) result) ;; TODO:
	   )
	  ((?d)                         ; %d - description
	   (push (attr 'user-description) result))
	  ((?l)                         ; %l - location
	   (push (attr 'user-location) result))
	  ((?L)                         ; %L - " [location]"
	   (let ((location (attr 'user-location)))
	     (unless (or (null location) (string= "" location))
	       (push (concat " [" location "]") result)) ))
	  ((?u)                         ; %u - url
	   (push (attr 'user-url) result))
          ((?U)                         ; %U - profile url
           (push (cadr (split-string (attr 'user-profile-url) "https*://")) result))
	  ((?j)                         ; %j - user.id
	   (push (format "%d" (attr 'user-id)) result))
	  ((?r)                         ; %r - in_reply_to_status_id
	   (let ((reply-id (attr 'in-reply-to-status-id))
		 (reply-name (attr 'in-reply-to-screen-name)))
	     (unless (or (null reply-id) (string= "" reply-id)
			 (null reply-name) (string= "" reply-name))
	       (let ((in-reply-to-string (format "in reply to %s" reply-name))
		     ;;(url (identica-get-status-url reply-id)) ;; TODO:
		     )
		 (add-text-properties
		  0 (length in-reply-to-string)
		  `(mouse-face highlight
			       face identica-uri-face
			       ;;uri ,url ;; TODO:
			       )
		  in-reply-to-string)
		 (push (concat " " in-reply-to-string) result)))))
	  ((?p)                         ; %p - protected?
	   (let ((protected (attr 'user-protected)))
	     (when (string= "true" protected)
	       (push "[x]" result))))
	  ((?c)                     ; %c - created_at (raw UTC string)
	   (push (attr 'created-at) result))
	  ((?C) ; %C{time-format-str} - created_at (formatted with time-format-str)
	   (push (identica-local-strftime
		       (or (match-string-no-properties 2 format-str) "%H:%M:%S")
		       (attr 'created-at))
		      result))
	  ((?@)                         ; %@ - X seconds ago
	   (let ((created-at
		  (apply
		   'encode-time
		   (parse-time-string (attr 'created-at))))
		 (now (current-time)))
	     (let ((secs (+ (* (- (car now) (car created-at)) 65536)
			    (- (cadr now) (cadr created-at))))
		   time-string url)
	       (setq time-string
		     (cond ((< secs 5) "less than 5 seconds ago")
			   ((< secs 10) "less than 10 seconds ago")
			   ((< secs 20) "less than 20 seconds ago")
			   ((< secs 30) "half a minute ago")
			   ((< secs 60) "less than a minute ago")
			   ((< secs 150) "1 minute ago")
			   ((< secs 2400) (format "%d minutes ago"
						  (/ (+ secs 30) 60)))
			   ((< secs 5400) "about 1 hour ago")
			   ((< secs 84600) (format "about %d hours ago"
						   (/ (+ secs 1800) 3600)))
			   (t (format-time-string "%I:%M %p %B %d, %Y" created-at))))
	       ;; (setq url (identica-get-status-url (attr 'id))) ;; TODO:
	       ;; make status url clickable
	       (add-text-properties
		0 (length time-string)
		`(mouse-face highlight
			     face identica-uri-face
			     ;; uri ,url ;; TODO:
			     )
		time-string)
	       (push time-string result))))
	  ((?t)                         ; %t - text
	   (push                   ;(clickable-text)
	    (attr 'text)
	    result))
	  ((?')                         ; %' - truncated
	   (let ((truncated (attr 'truncated)))
	     (when (string= "true" truncated)
	       (push "..." result))))
	  ((?f)                         ; %f - source
	   (push (attr 'source) result))
          ((?F)                         ; %F - ostatus-aware source
           (push (if (string= (attr 'source) "ostatus")
                     (cadr (split-string (attr 'user-profile-url) "https*://"))
                   (attr 'source)) result))
	  ((?#)                         ; %# - id
	   (push (format "%d" (attr 'id)) result))
	  ((?x)                         ; %x - conversation id (conteXt) - default 0
	   (push (attr 'conversation-id) result))
	  ((?h)
	   (let ((likes (attr 'favorited)))
	     (when (string= "true" likes)
	       (push (propertize "❤" 'face 'identica-heart-face) result))))
	  (t
	   (push (char-to-string c) result))))
      
      (push (substring format-str cursor) result)

      ;; Mix everything from result into a string and return it.
      (let ((formatted-status (apply 'concat (nreverse result))))
	(add-text-properties 0 (length formatted-status)
			     `(username, (attr 'user-screen-name)
                                         id, (attr 'id)
                                         text, (attr 'text)
                                         profile-url, (attr 'user-profile-url)
                                         conversation-id, (attr 'conversation-id))
			     formatted-status)
	formatted-status))))


;;
;; TODO: There's still repeated code! that has to be in a different function.
;;
(defun identica-find-and-add-screen-name-properties (text)
  "Finds all texts with URI format and add link properties to them."  
  (setq regex-index 0)
  (while regex-index
    (setq regex-index
	  (string-match identica-screen-name-regexp
			text
			regex-index))
    (when regex-index
      (let* ((matched-string (match-string-no-properties 0 text))
	     (screen-name (match-string-no-properties 1 text)))
	(add-text-properties (+ 1 (match-beginning 0))
			     (match-end 0)
			     `(mouse-face
			       highlight
			       face identica-uri-face
			       uri ,(concat "https://" (sn-account-server sn-current-account) "/" screen-name)
			       uri-in-text ,(concat "https://" (sn-account-server sn-current-account) "/" screen-name)
			       tag ,nil
			       group ,nil)
			     text))
      (setq regex-index (match-end 0))))
  text)


(defun identica-find-and-add-group-name-properties (text)
  "Finds all texts with URI format and add link properties to them."  
  (setq regex-index 0)
  (while regex-index
    (setq regex-index
	  (string-match identica-group-name-regexp
			text
			regex-index))
    (when regex-index
      (let* ((matched-string (match-string-no-properties 0 text))
	     (group-name (match-string-no-properties 1 text)))
	(add-text-properties (+ 1 (match-beginning 0))
			     (match-end 0)
			     `(mouse-face
			       highlight
			       face identica-uri-face
			       uri ,(concat "https://" (sn-account-server sn-current-account) "/group/" group-name)
			       uri-in-text ,(concat "https://" (sn-account-server sn-current-account) "/group/" group-name)
			       tag ,nil
			       group ,group-name)
			     text))
      (setq regex-index (match-end 0))))
  text)

(defun identica-find-and-add-tag-name-properties (text)
  "Finds all texts with URI format and add link properties to them."  
  (setq regex-index 0)
  (while regex-index
    (setq regex-index
	  (string-match identica-tag-name-regexp
			text
			regex-index))
    (when regex-index
      (let* ((matched-string (match-string-no-properties 0 text))
	     (tag-name (match-string-no-properties 1 text)))
	(add-text-properties (+ 1 (match-beginning 0))
			     (match-end 0)
			     `(mouse-face
			       highlight
			       face identica-uri-face
			       uri ,(concat "https://" (sn-account-server sn-current-account) "/tag/" tag-name)
			       uri-in-text ,(concat "https://" (sn-account-server sn-current-account) "/tag/" tag-name)
			       tag ,tag-name
			       group ,nil)
			     text))
      (setq regex-index (match-end 0))))
  text)

(defun identica-find-and-add-ur1-properties (text)
  "Finds all texts with URI format and add link properties to them."  
  (setq regex-index 0)
  (while regex-index
    (setq regex-index
	  (string-match identica-ur1-regexp
			text
			regex-index))
    (when regex-index
      (let* ((uri (match-string-no-properties 0 text)))
	(add-text-properties (+ 1 (match-beginning 0))
			     (match-end 0)
			     `(mouse-face
			       highlight
			       face identica-uri-face
			       uri ,uri
			       uri-in-text ,uri
			       tag ,nil
			       group ,nil)
			     text))
      (setq regex-index (match-end 0))))
  text)

(defun identica-find-and-add-http-url-properties (text)
  "Finds all texts with URI format and add link properties to them."  
  (setq regex-index 0)
  (while regex-index
    (setq regex-index
	  (string-match identica-http-url-regexp
			text
			regex-index))
    (when regex-index
      (let* ((uri (match-string-no-properties 0 text)))	     
	(add-text-properties (+ 1 (match-beginning 0))
			     (match-end 0)
			     `(mouse-face
			       highlight
			       face identica-uri-face
			       uri ,uri
			       uri-in-text ,uri
			       tag ,nil
			       group ,nil)
			     text))
      (setq regex-index (match-end 0))))
  text)

(defun identica-find-and-add-all-properties (text)
  "Finds all important text(like screen-names and tag-names), then add format and link properties to them."  
  (setq text (identica-find-and-add-screen-name-properties text))
  (setq text (identica-find-and-add-group-name-properties text))
  (setq text (identica-find-and-add-tag-name-properties text))
  (setq text (identica-find-and-add-ur1-properties text))
  (setq text (identica-find-and-add-http-url-properties text))
  text)

(defun identica-make-source-pretty (source)
  "Remove hyperlinks tags and make the caption clickable."
  (when (string-match "<a href=\"\\(.*\\)\">\\(.*\\)</a>" source)
    (let ((uri (match-string-no-properties 1 source))
	  (caption (match-string-no-properties 2 source)))
      (setq source caption)
      (add-text-properties
       0 (length source)
       `(mouse-face highlight
		    face identica-uri-face
		    source ,source)
       source)
      source)))


(provide 'identica-interface)