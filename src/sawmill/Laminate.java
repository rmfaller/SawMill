/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package sawmill;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author rmfaller
 */
class Laminate {

    Laminate(FileReader[] fra, boolean usespace, long startcut, long endcut) {
    }

    void laminate(BufferedReader[] lbra, boolean usenull, long startcut, long endcut) throws IOException {
        boolean[] filedone = new boolean[lbra.length];
        String[][] chdrs = new String[lbra.length][];
        String[][] data = new String[lbra.length][1];
        String brin;
        int lowvali = 0;
        int totalcells = 4;
        String replace = ",0";
        if (usenull) {
            replace = ",null";
        }
        for (int i = 0; i < lbra.length; i++) {
            filedone[i] = false;
            try {
                brin = lbra[i].readLine();
                chdrs[i] = brin.split(",");
                totalcells = totalcells + (chdrs[i].length - 4);
                data[i] = lbra[i].readLine().split(",");
            } catch (IOException ex) {
                Logger.getLogger(Laminate.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
        printheaders(chdrs);
        int x = 0;
        int lastcell;
        while (x < filedone.length) {
            lowvali = 0;
            lastcell = 4;
            for (int i = 1; i < filedone.length; i++) {
                if (Long.parseLong(data[lowvali][0]) > Long.parseLong(data[i][0])) {
                    lowvali = i;
                }
            }
            if ((Long.parseLong(data[lowvali][0]) >= startcut) && (Long.parseLong(data[lowvali][0]) <= endcut)) {
                System.out.print(data[lowvali][0] + ",");
//            System.out.print(data[lowvali][0] + lowvali + ",");
                System.out.print(data[lowvali][1] + ",");
                System.out.print(data[lowvali][2] + ",");
                System.out.print(data[lowvali][3]);
                for (int i = 0; i < lowvali; i++) {
                    for (int j = 4; j < (data[i].length); j++) {
                        System.out.print(replace);
                        lastcell++;
                    }
                }
                for (int i = 4; i < data[lowvali].length; i++) {
                    System.out.print("," + data[lowvali][i]);
                    lastcell++;
                }
                for (; lastcell < totalcells; lastcell++) {
                    System.out.print(replace);
                }
                System.out.println();
            }
            brin = lbra[lowvali].readLine();
            if (brin != null) {
                data[lowvali] = brin.split(",");
            } else {
                filedone[lowvali] = true;
                data[lowvali][0] = String.valueOf(Long.MAX_VALUE);
                x++;
            }
        }
        x = 0;
    }

    private void printheaders(String[][] chdrs) {
        System.out.print("clock,");
        System.out.print("Timestamp,");
        System.out.print("Logfile,");
        System.out.print("Time span(ms),");
        for (int i = 0; i < chdrs.length; i++) {
            for (int j = 4; j < chdrs[i].length; j++) {
                if ((j <= (chdrs[i].length - 2)) || (i < (chdrs.length - 1))) {
                    System.out.print(i + "-" + chdrs[i][j] + ",");
                } else {
                    System.out.print(i + "-" + chdrs[i][j]);
                }
            }
        }
        System.out.println();
    }

}
