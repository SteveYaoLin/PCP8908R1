module phase_difference (
    input  wire [14:0] data_phase_porta,  // Input phase A in 2Q13 format
    input  wire [14:0] data_phase_portb,  // Input phase B in 2Q13 format
    output wire  [14:0] phase_diff         // Output phase difference in 2Q13 format
);

    wire signed [15:0] phase_a_ext;       // Extended sign for phase A
    wire signed [15:0] phase_b_ext;       // Extended sign for phase B
    wire signed [15:0] diff;              // 16-bit result for phase difference

    // Extend inputs to 16-bit signed to handle overflow during subtraction
    assign phase_a_ext = {data_phase_porta[14], data_phase_porta};  // Sign-extend phase A
    assign phase_b_ext = {data_phase_portb[14], data_phase_portb};  // Sign-extend phase B

    // Perform subtraction with extended width
    assign diff = phase_a_ext - phase_b_ext;
    assign phase_diff = diff[14:0];
    // Handle overflow and ensure result is within 15-bit signed 2Q13 range
    // always @(*) begin
    //     if (diff > 15'sh1FFF)       // Maximum positive value for 15-bit 2Q13
    //         phase_diff = 15'sh1FFF; // Saturate to max positive
    //     else if (diff < -15'sh2000) // Minimum negative value for 15-bit 2Q13
    //         phase_diff = 15'sh2000; // Saturate to max negative
    //     else
    //         phase_diff = diff[14:0]; // Take lower 15 bits if within range
    // end

endmodule