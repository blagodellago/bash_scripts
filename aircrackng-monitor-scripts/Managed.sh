airmon-ng
airmon-ng check kill
interface=$1
ip link set ${interface} down
iw dev ${interface} set type managed
ip link set ${interface} up
service network-manager restart
iw ${interface} info
