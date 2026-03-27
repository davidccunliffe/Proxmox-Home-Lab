zone "${domain}" {
    type master;
    file "/etc/bind/db.${domain}";
    allow-transfer { ${secondary_ip}; };
    also-notify { ${secondary_ip}; };
};

zone "${reverse_zone}.in-addr.arpa" {
    type master;
    file "/etc/bind/db.${reverse_zone}";
    allow-transfer { ${secondary_ip}; };
    also-notify { ${secondary_ip}; };
};
