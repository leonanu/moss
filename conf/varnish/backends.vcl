backend CACHE_LB {
    .host = "192.168.192.11";
    .port = "80";

    .connect_timeout = 3s;
    .between_bytes_timeout = 5s;
    .first_byte_timeout = 10s;
    .saintmode_threshold = 20;

    .probe = {
        .interval = 5s;
        .timeout = 3s;
        .window = 10;
        .threshold = 8;

        .request = "GET /index.html HTTP/1.1"
                   "Host: mycheckweb.test.com"
                   "Connection: close"
                   "Accept-Encoding: foo/bar";
    }
}

#director BACKEND_01 round-robin {
#    { .backend = WEBSERVER1; }
#    { .backend = WEBSERVER2; }
#}
