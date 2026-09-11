function FindProxyForURL(url, host) {
  host = host.toLowerCase();

  if (host === "inetdata.se" || dnsDomainIs(host, ".inetdata.se")) {
    return "SOCKS5 127.0.0.1:1080";
  }

  return "DIRECT";
}
