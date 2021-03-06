/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package sawmill;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.text.ParseException;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

/**
 *
 * @author rmfaller
 */
public class SawMill {

    /**
     * @param args the command line arguments
     * @throws java.io.FileNotFoundException
     * @throws org.json.simple.parser.ParseException
     *
     * todos: reconcile all time to milliseconds by using timescale in json
     * configuration (s, m, n) create JSON for dstat,OpenAM, OpenIDM, OpenDJ
     * HTTP access --info to add info to condense output --example to print JSON
     * example file --sla for Service Level agreement adherence --harvest needs
     * to be implemented
     * @throws java.text.ParseException
     * @throws java.lang.InterruptedException
     */
    public static void main(String[] args) throws FileNotFoundException, IOException, ParseException, org.json.simple.parser.ParseException, InterruptedException {
        FileReader fr = null;
        FileReader[] fra = null;
        String cfn = null;
        String lf = null;
        String[] filenames = null;
        BufferedReader br = null;
        BufferedReader[] lbra = null;
        JSONObject config = null;
        JSONParser jp = new JSONParser();
        Condenser cdr = null;
        Laminate lmnt = null;
        Locater locater = null;
        String label = null;
        String locatestring = null;
        boolean runcondense = false;
        boolean runlaminate = false;
        boolean runlocate = false;
        boolean totalsonly = false;
        boolean html = false;
        boolean showtotals = false;
        boolean showheader = true;
        boolean sla = false;
        boolean filltimegap = false;
        boolean usenull = false;
        boolean sequence = false;
        long cut = 1;
        long startcut = 0;
        long endcut = Long.MAX_VALUE;
        int y = 0;
        if (args.length < 1) {
            help();
        }
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-c":
                case "-r":
                case "--condense":
                case "--rip":
                    br = new BufferedReader(new FileReader(args[i + 1]));
                    lf = args[i + 1];
                    cdr = new Condenser(config, br);
                    runcondense = true;
                    break;
                case "-u":
                case "--cut":
                    cut = Long.parseLong(args[i + 1]);
                    break;
                case "-?":
                case "--help":
                    help();
                    break;
                case "-p":
                case "--poi":
                    fr = new FileReader(args[i + 1]);
                    cfn = args[i + 1];
                    config = (JSONObject) jp.parse(fr);
                    break;
                case "-l":
                case "--laminate":
                    lbra = new BufferedReader[(args.length - i) - 1];
                    runlaminate = true;
                    y = 0;
                    for (int x = (i + 1); x < args.length; x++) {
                        lbra[y] = new BufferedReader(new FileReader(args[x]));
                        y++;
                    }
                    lmnt = new Laminate(fra, usenull, startcut, endcut);
                    break;
                case "-e":
                case "--usenull":
                    usenull = true;
                    break;
                case "-b":
                case "--label":
                    label = args[i + 1];
                    break;
/*                case "--location":
                    filenames = new String[(args.length - i) - 1];
                    runlocate = true;
                    y = 0;
                    for (int x = (i + 1); x < args.length; x++) {
                        filenames[y] = args[x];
                        y++;
                    }
                    break;
                 */
                case "-t":
                case "--totals":
                    showtotals = true;
                    break;
                case "-h":
                case "--html":
                    html = true;
                    break;
                case "-o":
                case "--totalsonly":
                    totalsonly = true;
                    break;
                case "-f":
                case "--filltimegap":
                    filltimegap = true;
                    break;
                case "--startcut":
                    startcut = Long.parseLong(args[i + 1]);
                    break;                
                case "--endcut":
                    endcut = Long.parseLong(args[i + 1]);
                    break;
                case "-n":
                case "--noheader":
                    showheader = false;
                    break;
                case "-s":
                case "--sla":
                    sla = true;
                    break;
                default:
                    break;
            }
        }
        if (runcondense && (cfn != null)) {
            cdr.condense(config, br, cut, cfn, showtotals, lf, sla, showheader, filltimegap, totalsonly, html, label, startcut, endcut);
        }
        if (runlaminate) {
            lmnt.laminate(lbra, usenull, startcut, endcut);
        }
        if (runlocate && (locatestring != null)) {
            locater = new Locater(filenames, locatestring);
            locater.locate(filenames, locatestring);
        }
    }

    private static void help() {
        String help = "\nSawMill usage when analyzing a log:"
                + "\n\trequired for ripping/analyzing:"
                + "\n\t\t--rip         | -r path and filename of log file to analyze"
                + "\n\t\t--poi         | -p path and filename of json configuration file on how to handle the log file to analyze"
                + "\n\tExample:"
                + "\n\tjava -jar ./dist/SawMill.jar --rip /path/to/file_to_analyze --poi /path/to/log_file_configuration.json"
                + "\n\toptions for ripping:"
                + "\n\t\t--totals      | -t prints a total for each column. Do not use this option when condensing a file to be laminated"
                + "\n\t\t--cut x       | -u where is x an integer and specifies the number of milliseconds used to condense the file by"
                + "\n\t\t--sla         | -s Lists the percentage of times the operation completed within the configured threshold"
                + "\n\t\t                   SLAs are assigned within the log_file_configuration.json file"
                + "\n\t\t--filltimegap | -f do not compress time"
                + "\nSawMill usage when laminating together more than one ripped log file:"
                + "\n\trequired for laminating:"
                + "\n\t\t--laminate    | -l path(s) and filename(s) of log files to laminate"
                + "\n\tExample:"
                + "\n\tjava -jar ./dist/SawMill.jar --laminate /path/to/rippedfile-0 /path/to/rippedfile-1 /path/to/rippedfile-n"
                + "\n\n\tExample of analyzing two log files and then laminating those files together:"
                + "\n\t\tjava -jar ./dist/SawMill.jar --rip $HOME/openidm/audit/access.audit.json-1of2 --poi $HOME/SawMill/poi/idm5-log.json > /tmp/idm-1of2.csv"
                + "\n\t\tjava -jar ./dist/SawMill.jar --rip $HOME/openidm/audit/access.audit.json-2of2 --poi $HOME/SawMill/poi/idm5-log.json > /tmp/idm-2of2.csv"
                + "\n\t\tjava -jar ./dist/SawMill.jar --laminate /tmp/idm-1of2.csv /tmp/idm-2of2.csv > /tmp/idm-combined.csv"
                + "\n";
        System.out.println(help);
    }

}
