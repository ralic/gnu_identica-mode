
    ;; identica-major-mode.el
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

    ;; Martes 24 De Julio Del 2012    


;; Lots of functions come from the original identica-mode. So the authors of those functions are lot of people!
;;
;; See git commit 30ffd973a7cae9e7deae5a075e80f5827af3df2a at savannah. 
;;


;;(require 'identica-mode)

(defvar identica-mode-map (make-sparse-keymap "Identi.ca"))
(defvar menu-bar-identica-mode-menu nil)

;; Menu
(unless menu-bar-identica-mode-menu
  (easy-menu-define
    menu-bar-identica-mode-menu identica-mode-map ""
    '("Identi.ca"
      ["Send an update" identica-update-status-interactive t]
      ["Send a direct message" identica-direct-message-interactive t]
      ["Re-dent someone's update" identica-redent t]
      ["Repeat someone's update" identica-repeat t]
      ["Add as favorite" identica-favorite t]
      ["Follow user" identica-follow]
      ["Unfollow user" identica-unfollow]
      ["--" nil nil]
      ["Friends timeline" identica-friends-timeline t]
      ["Public timeline" identica-public-timeline t]
      ["Replies timeline" identica-replies-timeline t]
      ["User timeline" identica-user-timeline t]
      ["Tag timeline" identica-tag-timeline t]
      ["--" nil nil]
      ["Group timeline" identica-group-timeline t]
      ["Join to this group" identica-group-join t]
      ["Leave this group" identica-group-leave t]
      )))


(defvar identica-mode-syntax-table nil "")

(if identica-mode-syntax-table
    ()
  (setq identica-mode-syntax-table (make-syntax-table))
  ;; (modify-syntax-entry ?  "" identica-mode-syntax-table)
  (modify-syntax-entry ?\" "w"  identica-mode-syntax-table))

(if identica-mode-map
    (let ((km identica-mode-map))
      (define-key km "\C-c\C-f" 'identica-friends-timeline)
      ;;      (define-key km "\C-c\C-i" 'identica-direct-messages-timeline)
      (define-key km "\C-c\C-r" 'identica-replies-timeline)
      (define-key km "\C-c\C-a" 'identica-public-timeline)
      (define-key km "\C-c\C-g" 'identica-group-timeline)
      ;;      (define-ley km "\C-c\C-j" 'identica-group-join)
      ;;      (define-ley km "\C-c\C-l" 'identica-group-leave)
      (define-key km "\C-c\C-t" 'identica-tag-timeline)
      (define-key km "\C-c\C-k" 'identica-stop)
      (define-key km "\C-c\C-u" 'identica-user-timeline)
      (define-key km "\C-c\C-c" 'identica-conversation-timeline)
      (define-key km "\C-c\C-o" 'identica-remote-user-timeline)
      (define-key km "\C-c\C-s" 'identica-update-status-interactive)
      (define-key km "\C-c\C-d" 'identica-direct-message-interactive)
      (define-key km "\C-c\C-m" 'identica-redent)
      (define-key km "\C-c\C-h" 'identica-toggle-highlight)
      (define-key km "r" 'identica-repeat)
      (define-key km "F" 'identica-favorite)
      (define-key km "\C-c\C-e" 'identica-erase-old-statuses)
      (define-key km "\C-m" 'identica-enter)
      (define-key km "R" 'identica-reply-to-user)
      (define-key km "A" 'identica-reply-to-all)
      (define-key km "\t" 'identica-next-link)
      (define-key km [backtab] 'identica-prev-link)
      (define-key km [mouse-1] 'identica-click)
      (define-key km "\C-c\C-v" 'identica-view-user-page)
      (define-key km "q" 'bury-buffer)
      (define-key km "e" 'identica-expand-replace-at-point)
      (define-key km "j" 'identica-goto-next-status)
      (define-key km "k" 'identica-goto-previous-status)
      (define-key km "l" 'forward-char)
      (define-key km "h" 'backward-char)
      (define-key km "0" 'beginning-of-line)
      (define-key km "^" 'beginning-of-line-text)
      (define-key km "$" 'end-of-line)
      (define-key km "n" 'identica-goto-next-status-of-user)
      (define-key km "p" 'identica-goto-previous-status-of-user)
      (define-key km [backspace] 'scroll-down)
      (define-key km " " 'scroll-up)
      (define-key km "G" 'end-of-buffer)
      (define-key km "g" 'identica-current-timeline)
      (define-key km "H" 'beginning-of-buffer)
      (define-key km "i" 'identica-icon-mode)
      (define-key km "s" 'identica-scroll-mode)
      (define-key km "t" 'identica-toggle-proxy)
      (define-key km "\C-k" 'identica-delete-notice)
      (define-key km "\C-c\C-p" 'identica-toggle-proxy)
      nil))

(defun identica-mode ()
  "Major mode for Identica."
  (interactive)
  (buffer-disable-undo (identica-buffer))
  (use-local-map identica-mode-map)
  (setq major-mode 'identica-mode)
  (setq mode-name identica-mode-string)
  (setq mode-line-buffer-identification
	`(,(default-value 'mode-line-buffer-identification)
	  (:eval (identica-mode-line-buffer-identification))))
  (identica-update-mode-line)
  (set-syntax-table identica-mode-syntax-table)
  (font-lock-mode -1)
  (if identica-soft-wrap-status
      (if (fboundp 'visual-line-mode)
          (visual-line-mode t)
	(if (fboundp 'longlines-mode)
	    (longlines-mode t))))
  (add-hook 'kill-buffer-hook 'identica-kill-buffer-function)
  (run-mode-hooks 'identica-mode-hook))


(defgroup identica-mode-faces nil
  "Identica mode Faces"
  :tag "Identica Mode Faces"
  :group 'identica-mode
  :group 'faces
  )

(defvar identica-username-face 'identica-username-face)
(defvar identica-uri-face 'identica-uri-face)
(defvar identica-reply-face 'identica-reply-face)
(defvar identica-stripe-face 'identica-stripe-face)
(defvar identica-highlight-face 'identica-highlight-face)

(defface identica-username-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-username-face nil :underline t)

(defface identica-reply-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-reply-face nil :background "DarkSlateGray")

(defface identica-stripe-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-stripe-face nil :background "LightSlateGray")

(defface identica-highlight-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-highlight-face nil :background "SlateGray")

(defface identica-uri-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-uri-face nil :underline t)

(defface identica-heart-face
  `((t nil)) "" :group 'identica-mode-faces)
(set-face-attribute 'identica-heart-face nil :foreground "firebrick1" :height 2.0)  


;; Icons
;;; ACTIVE/INACTIVE
(defconst identica-active-indicator-image
  (when (image-type-available-p 'xpm)
    '(image :type xpm
	    :ascent center
	    :data
	    "/* XPM */
static char * statusnet_xpm[] = {
\"16 16 14 1\",
\" 	c None\",
\".	c #8F0000\",
\"+	c #AB4040\",
\"@	c #D59F9F\",
\"#	c #E3BFBF\",
\"$	c #CE8F8F\",
\"%	c #C78080\",
\"&	c #FFFFFF\",
\"*	c #B96060\",
\"=	c #DCAFAF\",
\"-	c #C07070\",
\";	c #F1DFDF\",
\">	c #961010\",
\",	c #9D2020\",
\"    .......     \",
\"   .........    \",
\"  ...........   \",
\" ....+@#$+....  \",
\"....%&&&&&*.... \",
\"...+&&&&&&&+... \",
\"...=&&&&&&&$... \",
\"...#&&&&&&&#... \",
\"...=&&&&&&&@... \",
\"...*&&&&&&&-... \",
\"....@&&&&&&=... \",
\" ....-#&#$;&>.. \",
\" ..........,>.. \",
\"  ............. \",
\"    ............\",
\"       .      ..\"};")))


(defconst identica-inactive-indicator-image
  (when (image-type-available-p 'xpm)
    '(image :type xpm
	    :ascent center
	    :data
	    "/* XPM */
static char * statusnet_off_xpm[] = {
\"16 16 13 1\",
\" 	g None\",
\".	g #5B5B5B\",
\"+	g #8D8D8D\",
\"@	g #D6D6D6\",
\"#	g #EFEFEF\",
\"$	g #C9C9C9\",
\"%	g #BEBEBE\",
\"&	g #FFFFFF\",
\"*	g #A5A5A5\",
\"=	g #E3E3E3\",
\"-	g #B2B2B2\",
\";	g #676767\",
\">	g #747474\",
\"    .......     \",
\"   .........    \",
\"  ...........   \",
\" ....+@#$+....  \",
\"....%&&&&&*.... \",
\"...+&&&&&&&+... \",
\"...=&&&&&&&$... \",
\"...#&&&&&&&#... \",
\"...=&&&&&&&@... \",
\"...*&&&&&&&-... \",
\"....@&&&&&&=... \",
\" ....-#&#$&&;.. \",
\" ..........>;.. \",
\"  ............. \",
\"    ............\",
\"       .      ..\"};")))

(defun identica-update-mode-line ()
  "Update mode line."
  (force-mode-line-update))

(let ((props
       (when (display-mouse-p)
	 `(local-map
	   ,(purecopy (make-mode-line-mouse-map
		       'mouse-2 #'identica-toggle-activate-buffer))
	   help-echo "mouse-2 toggles automatic updates"))))
  (defconst identica-modeline-active
    (if identica-active-indicator-image
	(apply 'propertize " "
	       `(display ,identica-active-indicator-image ,@props))
      " "))
  (defconst identica-modeline-inactive
    (if identica-inactive-indicator-image
	(apply 'propertize "INACTIVE"
	       `(display ,identica-inactive-indicator-image ,@props))
      "INACTIVE")))

(provide 'identica-major-mode)