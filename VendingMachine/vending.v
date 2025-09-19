module vedingMachine (
    input clk,
    input rst,
    input enable_item,
    input enable_noi,      // Enable for number of items
    input enable_amt,
    input [3:0] selected_item,
    input [3:0] num_items,
    input [7:0] entered_amount,
    output reg error_flag,
    output reg [7:0] cost,
    output done
);

    // FSM states
    localparam [1:0]
        S0 = 2'b00,  // Idle / select item & number
        S1 = 2'b01,  // Wait for amount
        S2 = 2'b10,  // Transaction success
        S3 = 2'b11;  // Error

    // Item prices
    localparam [7:0]
        PRICE_0  = 8'd10, PRICE_1  = 8'd12, PRICE_2  = 8'd14, PRICE_3  = 8'd16,
        PRICE_4  = 8'd18, PRICE_5  = 8'd20, PRICE_6  = 8'd22, PRICE_7  = 8'd24,
        PRICE_8  = 8'd26, PRICE_9  = 8'd28, PRICE_10 = 8'd30, PRICE_11 = 8'd32;

    reg [1:0] state, next_state;
    reg [7:0] price;
    reg [3:0] inv [0:11];  // Inventory for 12 items (0-11)

    // State and inventory update logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0;
            error_flag <= 1'b0;
            // Initialize inventory
            inv[0]  <= 4'd5; inv[1]  <= 4'd5; inv[2]  <= 4'd5; inv[3]  <= 4'd5;
            inv[4]  <= 4'd5; inv[5]  <= 4'd5; inv[6]  <= 4'd5; inv[7]  <= 4'd5;
            inv[8]  <= 4'd5; inv[9]  <= 4'd5; inv[10] <= 4'd5; inv[11] <= 4'd5;
        end else begin
            state <= next_state;
            // Update inventory on successful transaction
            if (state == S1 && next_state == S2) begin
                inv[selected_item] <= inv[selected_item] - num_items;
            end
            // Set error flag when entering error state
            error_flag <= (next_state == S3);
        end
    end

    // Combinational logic
    always @(*) begin
        next_state = state;
        cost = 8'd0;
        price = 8'd0;

        // Set price for selected item (with validation)
        if (selected_item <= 4'd11) begin
            case (selected_item)
                4'd0:  price = PRICE_0;
                4'd1:  price = PRICE_1;
                4'd2:  price = PRICE_2;
                4'd3:  price = PRICE_3;
                4'd4:  price = PRICE_4;
                4'd5:  price = PRICE_5;
                4'd6:  price = PRICE_6;
                4'd7:  price = PRICE_7;
                4'd8:  price = PRICE_8;
                4'd9:  price = PRICE_9;
                4'd10: price = PRICE_10;
                4'd11: price = PRICE_11;
            endcase
        end

        case (state)
            S0: begin
                if (enable_item && enable_noi) begin
                    // Check if selected item is valid, num_items is valid, and enough inventory
                    if (selected_item <= 4'd11 && num_items > 0 && num_items <= 4'd5 && 
                        inv[selected_item] >= num_items) begin
                        next_state = S1;
                    end else begin
                        next_state = S3;
                    end
                end
            end
            S1: begin
                if (enable_amt) begin
                    // Calculate cost (price * num_items)
                    case (num_items)
                        4'd1: cost = price;
                        4'd2: cost = price + price;
                        4'd3: cost = price + price + price;
                        4'd4: cost = price + price + price + price;
                        4'd5: cost = price + price + price + price + price;
                        default: cost = 8'd0;
                    endcase

                    if (entered_amount == cost) begin
                        next_state = S2;
                    end else begin
                        next_state = S3;
                    end
                end
            end
            S2, S3: next_state = S0;  // Return to idle after success or error
            default: next_state = S0;
        endcase
    end

    // Transaction is done when in S2 (success) or S3 (error)
    assign done = (state == S2) || (state == S3);

endmodule
