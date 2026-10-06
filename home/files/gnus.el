;; Read Gmail over IMAP, send via the VPS -*- lexical-binding: t; -*-

(setq auth-sources '("~/.authinfo.gpg"))
(setq user-full-name "Thiago C. Silva"
      user-mail-address "librefos@newliber.com")
(setq gnus-select-method
      '(nnimap "gmail"
               (nnimap-address "imap.gmail.com")
               (nnimap-server-port 993)
               (nnimap-stream ssl)))
(setq gnus-secondary-select-methods
      '((nntp "lore" (nntp-address "nntp.lore.kernel.org"))))
(setq message-send-mail-function 'message-send-mail-with-sendmail
      sendmail-program "ssh-sendmail"
      message-sendmail-envelope-from 'header)
(setq gnus-message-archive-method gnus-select-method
      gnus-message-archive-group "[Gmail]/Sent Mail")
