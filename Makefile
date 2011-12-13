RELEASE=2.0

PACKAGE=fence-agents-pve
PKGREL=1
FAVER=3.1.7
FADIR=fence-agents-${FAVER}
FASRC=${FADIR}.tar.xz


DEB=${PACKAGE}_${FAVER}-${PKGREL}_amd64.deb

all: ${DEB}

${DEB} deb: ${FASRC}
	rm -rf ${FADIR}
	tar xf ${FASRC}
	cp -av debian ${FADIR}/debian
	cat ${FADIR}/doc/COPYRIGHT >>${FADIR}/debian/copyright
	cd ${FADIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEB}

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
	rm -rf *~ debian/*~ *.deb ${FADIR} ${PACKAGE}_*

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}
