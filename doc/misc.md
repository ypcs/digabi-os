Miscellaneous
===================================
Misc. things to remember.

## Environment Variables
    export DEBFULLNAME="Your Name"
    export DEBEMAIL="your@email"


## Tool for symlinking latest .ISO (for website, for VirtualBox testing)
    if [ -f latest.iso ]; then rm latest.iso ; fi && ln -s `ls -l digabi-livecd-*.iso |tail -n 1 |awk '{print $9}'` latest.iso


## Debian changelog
Create new changelog inside package

    dch --create -c changelog

Update changelog

    dch -c changelog
