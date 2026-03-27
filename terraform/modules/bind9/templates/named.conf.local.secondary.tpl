zone "${domain}" {
    type slave;
    file "/var/cache/bind/db.${domain}";
    masters { ${primary_ip}; };
};

zone "${reverse_zone}.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.${reverse_zone}";
    masters { ${primary_ip}; };
};
