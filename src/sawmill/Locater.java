/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package sawmill;

/**
 *
 * @author rmfaller
 */
class Locater extends Thread {

    Locater(String[] filenames, String ls) {
    }

    void locate(String[] filenames, String ls) throws InterruptedException {
        Worker[] workers = new Worker[filenames.length];
//        System.out.println("T file\t\tLog");
        for (int i = 0; i < filenames.length; i++) {
            workers[i] = new Worker(i, filenames[i], ls);
            workers[i].start();
        }
        for (int i = 0; i < filenames.length; i++) {
            workers[i].join();
        }
    }
}
