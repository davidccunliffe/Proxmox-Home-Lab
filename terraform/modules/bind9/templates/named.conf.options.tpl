options {
    directory "/var/cache/bind";

    forwarders {
%{ for fwd in forwarders ~}
        ${fwd};
%{ endfor ~}
    };

    dnssec-validation auto;

    listen-on { any; };
    listen-on-v6 { none; };

    allow-query { any; };
    allow-recursion { 172.16.0.0/16; 127.0.0.0/8; };

    recursion yes;
};
