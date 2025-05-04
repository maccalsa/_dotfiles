#!/bin/bash

# Display usage information
usage() {
    echo "Usage: $0 -t <type> -l <local port> -r <remote port> -d <destination host> -s <SSH server> [-u <SSH user>]"
    echo " -t Tunnel type: 'local' for local port forwarding, 'remote' for remote port forwarding"
    echo " -l Local port"
    echo " -r Remote port"
    echo " -d Destination host: the final destination host (only needed for local forwarding)"
    echo " -s SSH server: the SSH server to connect to for tunneling"
    echo " -u SSH user (optional): the username for SSH (default is the current user)"
    exit 1
}

# Check if the user has provided enough arguments
if [ $# -lt 8 ]; then
    usage
fi

# Parsing command line options
while getopts ":t:l:r:d:s:u:" opt; do
  case ${opt} in
    t )
      tunnel_type=$OPTARG
      ;;
    l )
      local_port=$OPTARG
      ;;
    r )
      remote_port=$OPTARG
      ;;
    d )
      dest_host=$OPTARG
      ;;
    s )
      ssh_server=$OPTARG
      ;;
    u )
      ssh_user=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage
      ;;
  esac
done

# Default SSH user to the current user if not provided
ssh_user=${ssh_user:-$(whoami)}

# Setting up the tunnel based on the type specified
case $tunnel_type in
    "local")
        if [ -z "$dest_host" ]; then
            echo "Destination host is required for local port forwarding."
            usage
        fi
        echo "Setting up local port forwarding..."
        echo "Forwarding local port $local_port to $dest_host:$remote_port through $ssh_server"
        ssh -L $local_port:$dest_host:$remote_port $ssh_user@$ssh_server -N
        ;;
    "remote")
        echo "Setting up remote port forwarding..."
        echo "Forwarding remote port $remote_port to local port $local_port through $ssh_server"
        ssh -R $remote_port:localhost:$local_port $ssh_user@$ssh_server -N
        ;;
    *)
        echo "Invalid tunnel type specified."
        usage
        ;;
esac