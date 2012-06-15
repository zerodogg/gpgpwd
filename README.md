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
- perl (version 5.10 or later)
- gpg
- JSON (perl module - debian package: libjson-perl)
- Try::Tiny (perl module - debian package: libtry-tiny-perl)

Optional:
- xclip
- git

To install all dependencies on a Debian-based distribution:
    aptitude install libjson-perl libtry-tiny-perl gnupg xclip git
