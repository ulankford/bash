for scsidev in /sys/class/scsi_disk/*

do

  [ -e "${scsidev}/device/rescan" ] || continue

  echo "Ordering rescan of SCSI device $(basename $scsidev)"

  echo '1' > "${scsidev}/device/rescan"

done

exit 0
