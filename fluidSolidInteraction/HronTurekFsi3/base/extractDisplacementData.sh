#!/bin/bash

awk '
# First pass: Calculate the mean of Ux and Uy
$1 >= 4 && $1 <= 6 {
  sum_Ux += $2;
  sum_Uy += $3;
  count++;
}
END {
  mean_Ux = sum_Ux / count;
  mean_Uy = sum_Uy / count;
  
  # Reset the stream and go through the file again for further calculations
  close(FILENAME);
  
  # Second pass: Detect two successive crossings of the mean and calculate amplitude per period
  state_Ux = 0;  # To track if the last crossing was from above or below the mean
  state_Uy = 0;
  while ((getline line < FILENAME) > 0) {
    split(line, fields);
    if (fields[1] >= 4 && fields[1] <= 6)
    {
        time = fields[1];
        Ux = fields[2];
        Uy = fields[3];

        # Track max/min for Ux and Uy
        if (Ux > max_Ux || NR == 1) {max_Ux = Ux};
        if (Ux < min_Ux || NR == 1) {min_Ux = Ux};
        if (Uy > max_Uy || NR == 1) {max_Uy = Uy};
        if (Uy < min_Uy || NR == 1) {min_Uy = Uy};

        # Detect mean crossings for Ux (crossing from below or above)
        if ((last_Ux - mean_Ux) * (Ux - mean_Ux) < 0) {
          if (state_Ux == 1) {  # If this is the second crossing in a full cycle
            amplitude_Ux = (max_Ux - min_Ux) / 2;  # Calculate amplitude
            sum_amplitude_Ux += amplitude_Ux;      # Sum the amplitudes
            count_periods_Ux++;
            max_Ux = Ux; min_Ux = Ux;  # Reset for next period
          }
          state_Ux = 1 - state_Ux;  # Toggle state (0->1 or 1->0)
        }

        # Detect mean crossings for Uy (crossing from below or above)
        if ((last_Uy - mean_Uy) * (Uy - mean_Uy) < 0) {
          if (state_Uy == 1) {  # If this is the second crossing in a full cycle
            amplitude_Uy = (max_Uy - min_Uy) / 2;  # Calculate amplitude
            sum_amplitude_Uy += amplitude_Uy;      # Sum the amplitudes
            count_periods_Uy++;
            max_Uy = Uy; min_Uy = Uy;  # Reset for next period
          }
          state_Uy = 1 - state_Uy;  # Toggle state (0->1 or 1->0)
        }

        last_Ux = Ux;
        last_Uy = Uy;
      }
  }

  # Calculate the mean amplitude over all periods
  if (count_periods_Ux > 0) {mean_amplitude_Ux = sum_amplitude_Ux / count_periods_Ux};
  if (count_periods_Uy > 0) {mean_amplitude_Uy = sum_amplitude_Uy / count_periods_Uy};

  # Estimate frequency based on average time between zero-crossings
  frequency_Ux = count_periods_Ux/ (6 - 4);
  frequency_Uy = count_periods_Uy/ (6 - 4);

  # Output the results
  print "Ux: mean =", 1000*mean_Ux, " amplitude =", 1000*mean_amplitude_Ux, "frequency =", frequency_Ux;
  print "Uy: mean =", 1000*mean_Uy, " amplitude =", 1000*mean_amplitude_Uy, "frequency =", frequency_Uy;
}' postProcessing/0/solidPointDisplacement_pointDisp.dat
