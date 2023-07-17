module Neuron(
	input CLOCK_50,//クロックを入れる
	input [1:0] KEY,//KEY[0]が押されたらresetされ、初期値が代入される
	input [3:0] SW, //追加
	input [3:0] GPIO_0,//追加
	output reg [7:0] LED, 
	output reg [3:0] GPIO_1
);
	reg signed [17:0] v1, v2; //ニューロン1の膜電位
	reg [5:0] count;//遅延用カウンタ。オーバーフローすると0になり、0になるとニューロンの電位計算演算が行われる
	reg signed [17:0] w1,w2,c1, c2, c3, c4;//ニューロンの状態を表す変数wと入力電流を表す変数cのレジスタを確保
	reg signed [17:0] v1new, w1new,w2new,v2new,v12,v13,v22,v23;//電位と内部状態更新用のレジスタ
	reg signed	[35:0]	temp_mult_out_v12,temp_mult_out_v22;//掛け算結果を保持しておくためのレジスタ
	reg signed	[35:0]	temp_mult_out_v13,temp_mult_out_v23;//掛け算結果を保持しておくためのレジスタ
	reg [17:0] spike_counter; //追加
	reg v2_active;

//analog simulation of FHN system
always @ (posedge CLOCK_50) 
begin//クロックの処理開始
	count <= #1 count + 1;//遅延用カウンタに毎クロック1を加算し、オーバーフローさせる
	if (KEY[0]==0) //reset
		begin//初期値代入
			reg signed	[35:0]	temp_mult_out_v12,temp_mult_out_v22;
			reg signed	[35:0]	temp_mult_out_v13,temp_mult_out_v23;
			LED[6:3] <= SW[3:0];
			spike_counter <= 0;
			v1 <= 18'h3_2148 ; //v1(0) = -0.870;
			w1 <= 18'h3_C9BB ; //w1(0) = -0.212;
			v2 <= 0 ; //v1(0) = -0.870;
			//c <= 18'h0_5999;//burst
			v1new<=0;
			w1new<=0;
			v2new<=0;
			v12<=0;
			v13<=0;
			v22<=0;
			v23<=0;
			if(SW[0]==1)
				begin
					c1<=18'h0_1000;
				end
			else
				begin
					c1<=0;
				end
			if(SW[1]==1)
				begin
					c2<=18'h0_1000;
				end
			else
				begin
					c2<=0;
				end
			if(SW[2]==1)
				begin
					c3<=18'h0_2000;
				end
			else
				begin
					c3<=0;
				end
			if(SW[3]==1)
				begin
					c4<=18'h0_2000;
				end
			else
				begin
					c4<=0;
				end
		end

	else if(count==0)//オーバーフローした場合
		begin
		if(GPIO_0[0]==1)//ニューロン2が発火している時
			begin
				v2=18'h0_1000;
				LED[1] = 1;
			end
		else//ニューロン２が発火していない時
			begin
					v2=0;	
					LED[1] = 0;	
			end
		temp_mult_out_v12=v1*(v1>>>1); 
		v12 = {temp_mult_out_v12[35], temp_mult_out_v12[32:16]};// v-squared/2
		temp_mult_out_v13=v12*(v1>>>1); 
		v13 = {temp_mult_out_v13[35], temp_mult_out_v13[32:16]};// v-cubed/4
		v1new = v1 + (((v1>>>2)-v13-(w1>>>2)+(c1>>>2)-(c2>>>2)+(c3>>>2)+(c4>>>2)-(v2>>>2))>>>4); //scale other vars to match v3
		w1new = w1 + (((v1>>>1)-(w1>>>1)) >>>9); // mult by a factor of 1/16
		//以下値の更新
		v1 = v1new ;
		w1 = w1new ;
		LED[0] <= spike_counter[17];
		
		if(v1[17]==0 & v1[16]==0 & v1[15]==1)
			begin
			 spike_counter <= #1 spike_counter+1;
			GPIO_1[0] <= 1;
			end
		else
			begin
			GPIO_1[0] <= 0;
			end
			
		end
end

endmodule