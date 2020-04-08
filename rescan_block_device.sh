for i in $(lsblk | grep -C 1 mpath | grep disk | awk '{print $1}')
do
echo "Ordering rescan for Block Device $i "
echo 1 > /sys/block/$i/device/rescan
done
