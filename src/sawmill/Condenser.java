/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package sawmill;

import java.io.BufferedReader;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

/**
 *
 * @author rmfaller
 */
class Condenser {

    Condenser(JSONObject config, BufferedReader br) {
    }

    void condense(JSONObject config, BufferedReader br, long cut, String cfn, boolean showtotals, String lf, boolean sla, boolean showheader, boolean filltimegap, boolean totalsonly, boolean html) {
        String timestampformat = config.get("timestampformat").toString();
        SimpleDateFormat sdf = new SimpleDateFormat(timestampformat);
        sdf.setTimeZone(TimeZone.getTimeZone("GMT"));
        String fielddelimiter = config.get("fielddelimiter").toString();
        String timestamp = null;
        String timescale = null;
        String lapsedtimefield = null;
        Date operationtime = null;
        float etime = 0;
        long epochtime = 0;
        long oldtime = 0;
        long starttime = 0;
        long[] slatime;
        char fd = 0;
        switch (fielddelimiter) {
            case "JSON": {
                fd = 'J';
            }
            break;
            case "TAB":
                fd = '\t';
                break;
            case "COMMA":
                fd = ',';
                break;
            case "SPACE":
                fd = ' ';
                break;
            default:
                break;
        }
//        String timefield = null;
        JSONArray poi = (JSONArray) config.get("poi");
        JSONObject[] pois = null;
        JSONObject logresponse = null;
        String[] brina = null;
        JSONArray[] identifiers = null;
        JSONParser jp = new JSONParser();
        int OPCNT = 0;
        int TIMEOP = 1;
        int TOTALOPCNT = 2;
        int TOTALTIMEOP = 3;
        int OPSUNDER = 4;
        int OPSOVER = 5;
        int TOTALOPSUNDER = 6;
        int TOTALOPSOVER = 7;
        long opcounter = 0;
        float[][] stats;
        String brin;
        if (!poi.isEmpty()) {
            pois = new JSONObject[poi.size()];
            identifiers = new JSONArray[poi.size()];
            slatime = new long[poi.size()];
            stats = new float[poi.size()][8];
            for (int i = 0; i < poi.size(); i++) {
                pois[i] = (JSONObject) config.get(poi.get(i));
                identifiers[i] = (JSONArray) pois[i].get("identifiers");
                slatime[i] = (long) pois[i].get("sla");
                for (int x = 0; x <= 7; x++) {
                    stats[i][x] = 0;
                }
            }
            try {
                while ((brin = br.readLine()) != null) {
                    int index = findPoi(brin, identifiers);
                    opcounter++;
//                    System.out.println("processing line " + opcounter + " : " + brin);
                    if (index != -1) {
                        if (fd == 'J') {
                            try {
                                JSONObject logentry = (JSONObject) jp.parse(brin);
                                logresponse = (JSONObject) logentry.get("response");
                                timestamp = (String) logentry.get(config.get("timestampfield"));
                                Long letime = (Long) logresponse.get(pois[index].get("lapsedtimefield"));
                                etime = letime.floatValue();
                                timescale = (String) logresponse.get(config.get("timescale"));
                            } catch (ParseException ex) {
                                Logger.getLogger(Condenser.class.getName()).log(Level.SEVERE, null, ex);
                            }
                        } else {
                            String logentry = brin.replaceAll("\\[", "").replaceAll("\\]", "");
//                            System.out.println("non-json log = " + logentry);
                            Long y = (Long) config.get("timestampfield");
                            brina = logentry.split(String.valueOf(fd));
                            if (timestampformat.contains(" ")) {
                                timestamp = brina[y.intValue()] + " " + brina[(y.intValue() + 1)];
                            } else {
                                timestamp = brina[y.intValue()];
                            }
                            timescale = (String) config.get("timescale");
                            lapsedtimefield = (String) pois[index].get("lapsedtimefield");
                            int fi;
                            String ta = null;
                            if (lapsedtimefield.matches("[-+]?\\d+(\\.\\d+)?")) {
                                ta = brina[Integer.parseInt(lapsedtimefield)];
                                ta = ta.replaceAll("\\\"", "").replaceAll("\\\"", "");
//                                                                    System.out.println("found: " + lapsedtimefield + "--" + ta);
                            } else {
                                fi = brina.length - 1;
                                while (!brina[fi].contains(lapsedtimefield) && (fi > 0)) {
                                    fi--;
                                }
                                if (fi < brina.length) {
                                    ta = brina[fi].substring(lapsedtimefield.length());
                                } else {
                                    System.out.println("can not find: " + lapsedtimefield);
                                    ta = "0";
                                }
                            }
                            etime = Float.parseFloat(ta);
                        }
//                        System.out.println("Pattern: " + sdf.toPattern());
//                        System.out.println("timestamp ->" + timestamp + "<-");
                        try {
                            operationtime = sdf.parse(timestamp.replaceAll("\\[", "").replaceAll("\\]", ""));
//                            operationtime = sdf.parse(timestamp);
                        } catch (java.text.ParseException ex) {
                            Logger.getLogger(Condenser.class.getName()).log(Level.SEVERE, null, ex);
                        }
                        float ts = 1;
                        if (etime > 0) {
                            switch (timescale) {
                                case "MILLISECONDS":
                                    ts = 1;
                                    break;
                                case "NANOSECONDS":
                                    ts = (1 / 1000);
                                    break;
                                case "SECONDS":
                                    ts = 1000;
                                    break;
                                case "MINUTES":
                                    ts = 60000;
                                    break;
                                default:
                                    ts = 1;
                                    break;
                            }
                        }
                        epochtime = operationtime.getTime();
                        if (oldtime == 0) {
                            oldtime = epochtime;
                            starttime = epochtime;
                            if (showheader && !html) {
                                printHeader(poi, sla);
                            }
                            if (showheader && html) {
                                printHTMLHeader(poi, sla);
                            }
                        }
                        stats[index][OPCNT]++;
                        stats[index][TOTALOPCNT]++;
                        slatime[index] = (long) pois[index].get("sla");
                        etime = etime * ts;
                        if (etime <= slatime[index]) {
                            stats[index][OPSUNDER]++;
                            stats[index][TOTALOPSUNDER]++;
                        } else {
                            stats[index][OPSOVER]++;
                            stats[index][TOTALOPSOVER]++;
                        }
                        stats[index][TIMEOP] = stats[index][TIMEOP] + etime;
                        stats[index][TOTALTIMEOP] = stats[index][TOTALTIMEOP] + etime;
                        if ((epochtime >= (oldtime + cut)) && (!totalsonly)) {
                            int x = 1;
                            if (filltimegap && (epochtime > (oldtime + cut))) {
                                while ((oldtime + (cut * x)) < epochtime) {
                                    System.out.print(oldtime + (cut * x));
                                    System.out.print("," + timestamp + ",");
                                    System.out.print(lf + ",");
                                    System.out.print(cut + ",");
                                    for (int i = 0; i < stats.length; i++) {
                                        System.out.print("0,0,");
                                        if (sla) {
                                            System.out.print("0,0,0,0,");
                                        }
                                    }
                                    System.out.println();
                                    x++;
                                }
                            }
                            System.out.print(epochtime);
                            System.out.print("," + timestamp + ",");
                            System.out.print(lf + ",");
                            if (filltimegap) {
                                System.out.print((epochtime - (oldtime + (cut * (x - 1)))) + ",");
                            } else {
                                System.out.print((epochtime - oldtime) + ",");
                            }
                            oldtime = epochtime;
                            for (int i = 0; i < stats.length; i++) {
                                System.out.format("%.0f%s", stats[i][OPCNT], ",");
                                if (stats[i][OPCNT] > 0) {
                                    System.out.format("%.2f%s", (stats[i][TIMEOP] / stats[i][OPCNT]), ",");
                                } else {
                                    System.out.print("0,");
                                }
                                if (sla) {
                                    System.out.print(slatime[i] + ",");
                                    System.out.format("%.0f%s", stats[i][OPSUNDER], ",");
                                    System.out.format("%.0f%s", stats[i][OPSOVER], ",");
                                    if (stats[i][OPSOVER] > 0) {
                                        System.out.format("%3.1f%s", ((stats[i][OPSUNDER] / stats[i][OPCNT]) * 100), "%");
                                    } else {
                                        System.out.print("100.0%");
                                    }
                                    System.out.print(",");
                                }
                            }
                            System.out.println();
                            for (int i = 0; i < stats.length; i++) {
                                stats[i][OPCNT] = 0;
                                stats[i][TIMEOP] = 0;
                                stats[i][OPSUNDER] = 0;
                                stats[i][OPSOVER] = 0;
                            }
                        }
                    }
                }
                if (((epochtime - oldtime) > 0) && (!totalsonly)) {
                    System.out.print(epochtime);
                    System.out.print("," + timestamp + ",");
                    System.out.print(lf + ",");
                    System.out.print((epochtime - oldtime) + ",");
                    oldtime = epochtime;
                    for (int i = 0; i < stats.length; i++) {
                        System.out.format("%.0f%s", stats[i][OPCNT], ",");
                        if (stats[i][OPCNT] > 0) {
                            System.out.format("%.2f%s", (stats[i][TIMEOP] / stats[i][OPCNT]), ",");
                        } else {
                            System.out.print("0,");
                        }
                        if (sla) {
                            System.out.print(slatime[i] + ",");
                            System.out.format("%.0f%s", stats[i][OPSUNDER], ",");
                            System.out.format("%.0f%s", stats[i][OPSOVER], ",");
                            if (stats[i][OPSOVER] > 0) {
                                System.out.format("%3.1f%s", ((stats[i][OPSUNDER] / stats[i][OPCNT]) * 100), "%");
                            } else {
                                System.out.print("100.0%");
                            }
                            System.out.print(",");
                        }
                    }
                    System.out.println();
                }
                if (showtotals || totalsonly) {
                    if (!html) {
                        System.out.print("Totals,,,");
                        System.out.print((epochtime - starttime) + ",");
                        for (int i = 0; i < stats.length; i++) {
                            System.out.format("%.0f%s", stats[i][TOTALOPCNT], ",");
                            if (stats[i][TOTALOPCNT] > 0) {
                                System.out.format("%.2f%s", (stats[i][TOTALTIMEOP] / stats[i][TOTALOPCNT]), ",");
                            } else {
                                System.out.print("0,");
                            }
                            if (sla) {
                                System.out.print(slatime[i] + ",");
                                System.out.format("%.0f%s", stats[i][TOTALOPSUNDER], ",");
                                System.out.format("%.0f%s", stats[i][TOTALOPSOVER], ",");
                                if (stats[i][TOTALOPSOVER] > 0) {
                                    System.out.format("%3.1f%s", ((stats[i][TOTALOPSUNDER] / stats[i][TOTALOPCNT]) * 100), "%");
                                } else {
                                    System.out.print("100.0%");
                                }
                                System.out.print(",");
                            }
                        }
                        System.out.println();
                    } else {
                        printHTML(sla, epochtime, starttime, stats, slatime, TOTALOPCNT, TOTALOPSOVER, TOTALOPSUNDER, TOTALTIMEOP, poi);
                    }
                }
            } catch (IOException ex) {
                Logger.getLogger(Condenser.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    private int findPoi(String brin, JSONArray[] identifiers) {
        int x = 0;
        int index = -1;
        int findcount = 0;
        boolean found = false;
//        System.out.println("brin = " + brin);
        while ((x < identifiers.length) && (!found)) {
            findcount = 0;
            for (int i = 0; i < identifiers[x].size(); i++) {
                if (brin.contains((String) identifiers[x].get(i))) {
//                    System.out.println("id = " + identifiers[x].get(i));
                    findcount++;
                }
            }
            if (findcount == identifiers[x].size()) {
                found = true;
                index = x;
            }
            x++;
        }
        return (index);
    }

    private void printHeader(JSONArray poi, boolean sla) {
        System.out.print("clock,");
        System.out.print("Timestamp,");
        System.out.print("Logfile,");
        System.out.print("Timespan(ms),");
        for (int i = 0; i < poi.size(); i++) {
            System.out.print((String) (poi.get(i)) + ".ops,");
            System.out.print((String) (poi.get(i)) + ".time-op,");
            if (sla) {
                System.out.print((String) (poi.get(i)) + ".sla,");
                System.out.print((String) (poi.get(i)) + ".under,");
                System.out.print((String) (poi.get(i)) + ".over,");
                System.out.print((String) (poi.get(i)) + ".percent,");
            }
        }
        System.out.println();
    }

    private void printHTMLHeader(JSONArray poi, boolean sla) {
        System.out.println("clock");
        System.out.println("Timestamp");
        System.out.println("Logfile");
        System.out.println("Timespan(ms)");
        System.out.println("<table cellpadding=\"4\" border=\"1\">");
        System.out.println("<tbody>");
        System.out.println("<tr><font face=\"Consolas\">");
        System.out.println("<td align=\"center\">Operation Type</td>");
        System.out.println("<td align=\"center\">Operations</td>");
        System.out.println("<td align=\"center\">Average Time per Operation</td>");
        System.out.println("<td align=\"center\">Under threshold</td>");
        System.out.println("<td align=\"center\">Over threshold</td>");
        System.out.println("<td align=\"center\">Threshold</td>");
        System.out.println("<td align=\"center\">Percentage under threshold</td>");
        System.out.println("</font></tr>");
    }

    private void printHTML(boolean sla, long epochtime, long starttime, float[][] stats, long[] slatime, int TOTALOPCNT, int TOTALOPSOVER, int TOTALOPSUNDER, int TOTALTIMEOP, JSONArray poi) {
        for (int i = 0; i < stats.length; i++) {
            System.out.println("<pre><tr>");
            System.out.println("<td>" + poi.get(i) + "</td>");
            System.out.format("%s%.0f%s", "<td>", stats[i][TOTALOPCNT], "</td>");
            if (stats[i][TOTALOPCNT] > 0) {
                System.out.format("%s%.2f%s", "<td>", (stats[i][TOTALTIMEOP] / stats[i][TOTALOPCNT]), "</td>");
            } else {
                System.out.print("<td>0</td>");
            }
            if (sla) {
                System.out.println("<td>");
                System.out.format("%.0f%s", stats[i][TOTALOPSUNDER], "</td>");
                System.out.println("<td>");
                System.out.format("%.0f%s", stats[i][TOTALOPSOVER], "</td>");
                System.out.print("<td>" + slatime[i] + "</td>");
                if (stats[i][TOTALOPSOVER] > 0) {
                    System.out.format("%s%3.1f%s", "<td>", ((stats[i][TOTALOPSUNDER] / stats[i][TOTALOPCNT]) * 100), "%</td>");
                } else {
                    System.out.print("<td>100.0%</td>");
                }
            }
            System.out.println("</tr></pre>");
        }
        System.out.println("<tr bgcolor=\"#ffff99\"><td>Time span</td><td>=</td><td>" + (epochtime - starttime) + "ms</td><td>(" + ((epochtime - starttime) / 1000) + " seconds)</td><td>("+ (((epochtime - starttime) / 1000) / 60) + " minutes)</td>");
        System.out.println("</tr></tbody>");
        System.out.println("</table>");
    }

}
