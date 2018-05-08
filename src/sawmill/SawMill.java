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
        String locatestring = null;
        boolean runcondense = false;
        boolean runlaminate = false;
        boolean runlocate = false;
        boolean showtotals = false;
        boolean sla = false;
        long cut = 1;
        int y = 0;
        if (args.length < 1) {
            help();
        }
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--condense":
                    br = new BufferedReader(new FileReader(args[i + 1]));
                    lf = args[i + 1];
                    cdr = new Condenser(config, br);
                    runcondense = true;
                    break;
                case "--cut":
                    cut = Long.parseLong(args[i + 1]);
                    break;
                case "--help":
                    help();
                    break;
                case "--configuration":
                    fr = new FileReader(args[i + 1]);
                    cfn = args[i + 1];
                    config = (JSONObject) jp.parse(fr);
                    break;
                case "--laminate":
                    lbra = new BufferedReader[(args.length - i) - 1];
                    runlaminate = true;
                    y = 0;
                    for (int x = (i + 1); x < args.length; x++) {
                        lbra[y] = new BufferedReader(new FileReader(args[x]));
                        y++;
                    }
                    lmnt = new Laminate(fra);
                    break;
                case "--locate":
                    locatestring = args[i + 1];
                    break;
                case "--location":
                    filenames = new String[(args.length - i) - 1];
                    runlocate = true;
                    y = 0;
                    for (int x = (i + 1); x < args.length; x++) {
                        filenames[y] = args[x];
                        y++;
                    }
                    break;

                case "--totals":
                    showtotals = true;
                    break;
                case "--sla":
                    sla = true;
                    break;
                default:
                    break;
            }
        }
        if (runcondense && (cfn != null)) {
            cdr.condense(config, br, cut, cfn, showtotals, lf, sla);
        }
        if (runlaminate) {
            lmnt.laminate(lbra);
        }
        if (runlocate && (locatestring != null)) {
            locater = new Locater(filenames, locatestring);
            locater.locate(filenames, locatestring);
        }
    }

    private static void help() {
        String help = "\nSawMill usage:"
                + "\njava -jar SawMill.jar --condense file_to_condense --configuration configuration/log_file_configuration.json"
                + "\n\toptions when condensing:"
                + "\n\t\t--totals : prints a total for each column. Do not use this option when condensing a file to be laminated."
                + "\n\t\t--cut x  : where is x an integer and specifies the number of milliseconds used to condense the file by."
                + "\n\t\t--sla    : includes the number of operations the meet SLAs, exceeded SLAs, and a percentage of operations that met SLAs."
                + "\n\t\t           SLAs are assigned within the log_file_configuration."
                + "\n\nor\n"
                + "\njava -jar SawMill.jar --laminate condensedfile0 condensedfile1 condensedfilen..."
                + "\n";
        System.out.println(help);
    }

}
