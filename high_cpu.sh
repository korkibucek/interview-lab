#!/bin/bash

# Simulate a high CPU usage process
cat <<EOT >> /usr/local/bin/cpu_load.sh
#!/bin/bash
while true; do
   :
done
EOT
chmod +x /usr/local/bin/cpu_load.sh
nohup /usr/local/bin/cpu_load.sh &