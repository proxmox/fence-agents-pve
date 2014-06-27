Installation du module 'fencing' pour online sur proxmox a partir des sources
=============================================================================

BIG FAT WARNING
===============

# this is a bad idea!

you need at least three machines, and so the drbd and fencing config will need adaptation


remplacer
=========

 * YOUR_ONLINE_API_KEY par le token privé obtenu de https://console.online.net/fr/api/access
 * OTHER indique toujours la machine qui est pas utilisé pour la construction
  * YOURMACHINEIP OTHERMACHINEIP par les adresses ip des machines
  * ONLINE_ID OTHER_ONLINE_ID par les identifiants online des serveurs (seul les chiffres, sans le préfix sd-)
  * MACHINEHOSTNAME OTHER_MACHINEHOSTNAME le nom d'hote des machines, défault est sd-ONLINE_ID par online
 * IncrementPreviousValue en incrémentant la valeur précédente

Construction des paquets
------------------------

#Création d'un chroot

    # cd
    # debootstrap --variant=minbase wheezy ./wheezy-proxmox-devel http://http.debian.net/debian/
    # mkdir /root/bin
    # cat > /root/bin/enter-proxmox-devel << EOF
```bash
#!/bin/bash
sigs="SIGTERM SIGHUP SIGINT SIGQUIT SIGKILL SIGABRT SIGTSTP SIGTTIN SIGTTOU"
for sig in $sigs; do
  trap "cleanup Trapped signal $sig" $sig &>/dev/null
done

cleanup() {
  echo "$@"
  umount /root/wheezy-proxmox-devel/proc /root/wheezy-proxmox-devel/sys /root/wheezy-proxmox-devel/dev/pts /root/wheezy-proxmox-devel/dev
}

mount -t proc procfs /root/wheezy-proxmox-devel/proc
mount -t sysfs sysfs /root/wheezy-proxmox-devel/sys
mount --rbind /dev /root/wheezy-proxmox-devel/dev

debian_chroot="wheezy-proxmox-devel" chroot /root/wheezy-proxmox-devel bash -l
cleanup "Bye..."
EOF
```
    # chmod +x /root/bin/enter-proxmox-devel
    # echo 'export PATH="$PATH:/root/bin"' >> /root/.bashrc
    # cp /etc/apt/sources.list /root/wheezy-proxmox-devel/etc/apt/sources.list
    # logout


#Construction des paquets

    # enter-proxmox-devel
    # apt-get update
    # apt-get install wget
    # wget -O - "http://download.proxmox.com/debian/key.asc" | apt-key add -
    # apt-get update
    # apt-get upgrade
    # apt-get install wget debhelper autotools-dev quilt libnss3-dev python-pycurl python-pexpect libxml2-utils xsltproc libnet-telnet-perl python-pip python-virtualenv python-all pkg-config lintian
    # mkdir -p /usr/src/pvebuild
    # cd /usr/src/pvebuild

    # virtualenv py2dsc
    # . py2dsc/bin/activate
    # pip install stdeb
    # deactivate

    # py2dsc/bin/pypi-download slumber --release=0.6.0
    # py2dsc/bin/pypi-download requests
    # py2dsc/bin/pypi-download python-hpilo
    # py2dsc/bin/py2dsc-deb requests-2.3.0.tar.gz
    # cp deb_dist/python-requests_2.3.0-1_all.deb .
    # rm -fr deb_dist/
    # py2dsc/bin/py2dsc-deb slumber-0.6.0.tar.gz
    # cp deb_dist/python-slumber_0.6.0-1_all.deb .
    # rm -fr deb_dist/
    # py2dsc/bin/py2dsc-deb python-hpilo-2.6.2.tar.gz
    # cp deb_dist/python-python-hpilo_2.6.2-1_all.deb .
    # rm -fr deb_dist/
    # dpkg -i python-requests_2.3.0-1_all.deb python-slumber_0.6.0-1_all.deb python-python-hpilo_2.6.2-1_all.deb

    # git clone git://github.com/soul9/fence-agents-pve.git
    # cd fence-agents-pve
    # make all
    # cp fence-agents-pve_4.0.5-2_amd64.deb ..
    # logout
    # cp wheezy-proxmox-devel/usr/src/pvebuild/*.deb /usr/src/
    # scp /usr/src/python-requests_2.3.0-1_all.deb /usr/src/python-python-hpilo_2.6.2-1_all.deb /usr/src/python-slumber_0.6.0-1_all.deb /usr/src/fence-agents-pve_4.0.5-2_amd64.deb root@OTHERMACHINEIP:/usr/src

#Installation des paquets

    # dpkg -i /usr/src/python-requests_2.3.0-1_all.deb /usr/src/python-slumber_0.6.0-1_all.deb /usr/src/fence-agents-pve_4.0.5-2_amd64.deb /usr/src/python-python-hpilo_2.6.2-1_all.deb
    # ssh root@OTHERMACHINE "dpkg -i /usr/src/python-requests_2.3.0-1_all.deb /usr/src/python-slumber_0.6.0-1_all.deb /usr/src/fence-agents-pve_4.0.5-2_amd64.deb /usr/src/python-python-hpilo_2.6.2-1_all.deb"

#Configuration

    # cp /etc/pve/cluster.conf /etc/pve/cluster.conf.new


cluster.conf.new devrait contenir
```xml
<?xml version="1.0"?>
<cluster config_version="IncrementPreviousValue" name="BeabaCluster">
  <cman expected_votes="1" keyfile="/var/lib/pve-cluster/corosync.authkey" two_node="1"/>
  <fencedevices>
    <fencedevice agent="fence_onlinenet" name="fence_online_ilo" passwd="YOUR_ONLINE_API_KEY" method="ilo" />
  </fencedevices>
  <clusternodes>
    <clusternode name="MACHINEHOSTNAME" nodeid="1" votes="1">
      <fence>
        <method name="onlinenet">
          <device myip="OTHERMACHINEIP" name="fence_online_ilo" remoteid="ONLINE_ID"/>
        </method>
      </fence>
    </clusternode>
    <clusternode name="OTHER_MACHINEHOSTNAME" nodeid="2" votes="1">
      <fence>
        <method name="onlinenet">
          <device myip="YOURMACHINEIP" name="fence_online_ilo" remoteid="OTHER_ONLINE_ID"/>
        </method>
      </fence>
    </clusternode>
  </clusternodes>
  <rm />
</cluster>

```

ajouter dans le fichier /etc/default/redhat-cluster-pve sur les deux machines:

    FENCE_JOIN="yes"

Sur l'interface proxmox

 * Vue Datacenter
 * dans l'onglet HA
 * activer la nouvelle configuration (bouton 'Activate')

Pour activer la gestion Haute Disponibilité pour une machine virtuelle existante

 * Vue Datacenter
 * dans l'onglet HA
 * bouton add
 * HA managed VM/CT
 * mettre l'id numérique de la VM souhaité
 * clicker activate pour activer la nouvelle configuration cluster
