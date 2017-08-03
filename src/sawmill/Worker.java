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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author rmfaller
 */
class Worker extends Thread {

    private final int threadid;
    private final String filename;
    private final String locate;

    Worker(int threadid, String filename, String locate) {
        this.threadid = threadid;
        this.filename = filename;
        this.locate = locate;
    }

    @Override
    public void run() {
        try {
            String brin;
            BufferedReader br = null;
            try {
                br = new BufferedReader(new FileReader(this.filename));
            } catch (FileNotFoundException ex) {
                Logger.getLogger(Worker.class.getName()).log(Level.SEVERE, null, ex);
            }
            while ((brin = br.readLine()) != null) {
                if (brin.contains((String) locate)) {
                    System.out.println(this.filename + "-> " + brin);
                }
            }
            
        } catch (IOException ex) {
            Logger.getLogger(Worker.class.getName()).log(Level.SEVERE, null, ex);
        }

    }
}
