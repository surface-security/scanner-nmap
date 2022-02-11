import json
import argparse
from libnmap.parser import NmapParser
from libnmap.process import NmapProcess


def build_parser():
    parser = argparse.ArgumentParser(description='Start the nmap scan.')
    parser.add_argument('-p', '--ports', type=str,
                        help='Ports that need to be scanned.')
    parser.add_argument('-T', type=int, default=4,
                        help='Set the nmap timing template')
    parser.add_argument('-S', action='store_true',
                        help='Use SYN scan (instead of Connect)')
    parser.add_argument('inputfile', type=str,
                        help='Fetch the IPs from a particular file.')
    return parser


def main(args):
    scan_list = [line.strip() for line in open(args.inputfile)]
    ip_list = { }
    # Doing a normal scan on the inputed ports
    print(f"[+] Started scan on ports {args.ports if args.ports else '<default>'}.")
    nmap_opt = [
        '-oX', '/tmp/scan.xml',
        '-Pn', '-v', '-T', str(args.T),
        '-n',
        '-sS' if args.S else '-sT',
    ]
    if args.ports:
        nmap_opt.extend(['-p', args.ports])
    nm = NmapProcess(targets=scan_list, options=' '.join(nmap_opt), safe_mode=False)
    nm.run()
    if nm.rc != 0:
        print(nm.stdout)
    nmap_report = NmapParser.parse_fromfile("/tmp/scan.xml")
    for host in nmap_report.hosts:
        ip_list[host.address] = [i[0] for i in host.get_open_ports()]

    with open(f'/output/nmap_scan_latest.json', 'a+') as outfile:
        json.dump(ip_list, outfile, sort_keys=True, indent=4)

if __name__ == '__main__':
    main(build_parser().parse_args())