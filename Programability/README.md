# **DESTINATION METRICS**

[Lever Inc.](http://www.leverinc.org)

## **Introduction**

Destination Metrics, founded at Lever Inc., is a project designed to quantify
the relationship between cultural and industrial businesses in Northern Berkshire
County.

## **How Data Is Gathered**

When smartphones send out "probe requests" for wireless internet(Wi-Fi), our device
called the Destination Meter gathers the smartphones MAC Address and Serial ID
from that probe request.

## **Hardware Required**
* Raspberry Pi (any model)
* Tenda 150Mbps Wireless N high Gain USB Adapter
* 8GB MicroSD card
* Ethernet Cable

## **Software Required**
* Debian "Wheezy"
* Ruby
* PHP
* MySQL
* Amazon Web Services(AWS)


# **Setup**

### Clone The Repository
`` `git clone https://github.com/adamo57/DestinationMetrics.git` ``

### Move The Launcher to root
`` `cd DestinationMetrics/Programability/` ``
`` `mv ./launcher.sh ~` ``
`` `cd ~` ``

### Make launcher.sh executable
`` `sudo chmod 775 launcher.sh` ``

### Run the Launcher
`` `./launcher.sh` ``
