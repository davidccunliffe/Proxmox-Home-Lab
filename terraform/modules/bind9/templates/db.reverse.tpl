$TTL    604800
@       IN      SOA     ${primary_hostname}.${domain}. admin.${domain}. (
                        ${serial}      ; Serial
                        3600           ; Refresh
                        900            ; Retry
                        604800         ; Expire
                        86400 )        ; Negative Cache TTL

; Name servers
@       IN      NS      ${primary_hostname}.${domain}.
@       IN      NS      ${secondary_hostname}.${domain}.

; PTR records
%{ for ptr_name, fqdn in ptr_records ~}
${ptr_name}    IN      PTR     ${fqdn}.
%{ endfor ~}
