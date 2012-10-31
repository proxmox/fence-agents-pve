RELEASE=2.2

PACKAGE=fence-agents-pve
PKGREL=1
FAVER=3.1.9
FADIR=fence-agents-${FAVER}.6-582aa5
FASRC=${FADIR}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
DEB=${PACKAGE}_${FAVER}-${PKGREL}_${ARCH}.deb

all: ${DEB}

${DEB} deb: ${FASRC}
	rm -rf ${FADIR}
	tar xf ${FASRC}
	cp -av debian ${FADIR}/debian
	cat ${FADIR}/doc/COPYRIGHT >>${FADIR}/debian/copyright
	cd ${FADIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEB}

${RHCSRC} download:
	rm -rf fence-agents.git
	git clone git://git.fedorahosted.org/fence-agents.git fence-agents.git
	cd fence-agents.git; ./autogen.sh; ./configure; make dist
	mv fence-agents.git/fence-agents-*.tar.gz .

.PHONY: upload
upload: ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

clean:
	rm -rf *~ debian/*~ *.deb ${FADIR} ${PACKAGE}_* fence-agents.git

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}
