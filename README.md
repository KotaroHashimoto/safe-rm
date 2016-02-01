# safe-rm
This script protects the system from unintended disastrous rm command ("rm -rf /", "rm -rf ~", etc.)  

# how to install
Rename the existing "rm" binary to "rm.org", and install the Python script "rm" instead.

```bash
sudo mv /bin/rm /bin/rm.org
sudo cp ./rm /bin/rm
```
