echo "Copying src files..."
for file in `ls src/*.py`; do
  /bin/echo -n "[$file]..."
  /usr/local/bin/ampy --port /dev/cu.SLAB_USBtoUART put $file
  /bin/echo "done."
done
