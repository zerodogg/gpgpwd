gpgpwd
======

gpgpwd is a terminal-based password manager. It stores a list of passwords
in a GnuPG encrypted file, and allows you to easily retrieve, change and add to
that file as needed. It also generates random passwords that you can use,
easily allowing you to have one "master password" (for your gpg key), with
one unique and random password for each website or service you use, ensuring
that your other accounts stay safe even if one password gets leaked.

gpgpwd can also utilize git to allow you to easily synchronize your
passwords between different machines.

Dependencies
------------
Required:
- perl
- gpg

Optional:
- xclip
- git
