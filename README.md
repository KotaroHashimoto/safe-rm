# safe-rm
This script protects the system from unintended disaster rm command ("rm -rf /", "rm -rf ~", etc.) 

rename the existing "rm" binary to "rm.bin", and install the Python script "rm" instead.


TODO:
How to capture '~', '/', '*' as arguments without expanding them ??
