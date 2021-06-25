airmon-ng
airmon-ng check kill
interface=$1
ip link set ${interface} down
iw dev ${interface} set type monitor
ip link set ${interface} up
iw ${interface} set txpower fixed 3000
iw ${interface} info
