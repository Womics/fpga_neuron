

module neurons(
	input CLOCK_50,//クロックを入れる
	input [1:0] KEY,//KEY[0]が押されたらresetされ、初期値が代入される
	output reg [3:0] count,//遅延用カウンタ。オーバーフローすると0になり、0になるとニューロンの電位計算演算が行われる
	output reg signed [17:0] v1,v2,//それぞれニューロン1,ニューロン2の膜電位
	output reg signed [17:0] v1_active,v2_active//ニューロン1,2が活動しているフラグ
);
	reg signed [17:0]w1,w2,c;//ニューロンの状態を表す変数wと入力電流を表す変数cのレジスタを確保
	reg signed [17:0] v1new, w1new,w2new,v2new,v12,v13,v22,v23;//電位と内部状態更新用のレジスタ
	reg 	signed	[35:0]	temp_mult_out_v12,temp_mult_out_v22;//掛け算結果を保持しておくためのレジスタ
	reg 	signed	[35:0]	temp_mult_out_v13,temp_mult_out_v23;//掛け算結果を保持しておくためのレジスタ
//analog simulation of FHN system
always @ (posedge CLOCK_50) 
begin//クロックの処理開始
	count <= #1 count + 1;//遅延用カウンタに毎クロック1を加算し、オーバーフローさせる
	if (KEY[0]==0) //reset
		begin//初期値代入
			v1 <= 18'h3_2148 ; //v1(0) = -0.870;
			w1 <= 18'h3_C9BB ; //w1(0) = -0.212;
			v2 <= 18'h3_2148 ; //v1(0) = -0.870;
			w2 <= 18'h3_C9BB ; //w1(0) = -0.212;
			c<=18'h0_2999;//スイッチ処理で変更
			//c <= 18'h0_5999;//burst
			v1new<=0;
			w1new<=0;
			w2new<=0;
			v2new<=0;
			v12<=0;
			v13<=0;
			v22<=0;
			v23<=0;
			reg 	signed	[35:0]	temp_mult_out_v12,temp_mult_out_v22;
			reg 	signed	[35:0]	temp_mult_out_v13,temp_mult_out_v23;

		end
	else if(count==0)//オーバーフローした場合
		begin
			if (v1[17]==1&v1[16]==1)//ニューロン1が発火する時
			begin
				if(v2[17]==1&v2[16]==1)//ニューロン2が発火するとき
				begin
					v1_active=18'h0_5999;
					v2_active=18'h0_5999;
				end
				else//ニューロン2が発火していない時
				begin
					v1_active=18'h0_5999;
					v2_active=0;
				end
			end
			else//ニューロン1が発火していない時
			begin
				if(v2[17]==1&v2[16]==1)//ニューロン2が発火している時
				begin
					v1_active=0;
					v2_active=18'h0_5999;
				end
				else//ニューロン２が発火していない時
				begin
					v1_active=0;
					v2_active=0;		
				end
			end
			temp_mult_out_v12=v1*(v1>>>1); 
			v12=	{temp_mult_out_v12[35], temp_mult_out_v12[32:16]};// v-squared/2
			temp_mult_out_v13<=v12*(v1>>>1); 
			v13=	{temp_mult_out_v13[35], temp_mult_out_v13[32:16]};// v-cubed/4
			v1new = v1 + (((v1>>>2)-v13-(w1>>>1)+(c>>>2)-(v2_active>>>2))>>>4); //scale other vars to match v3
			w1new = w1 + (((v1>>>1)-(w1>>>1)) >>>9); // mult by a factor of 1/16
			
			temp_mult_out_v22=v2*(v2>>>1); 	
			v22=	{temp_mult_out_v22[35], temp_mult_out_v22[32:16]};// v-squared/2
			temp_mult_out_v13<=v22*(v2>>>1); 
			v23=	{temp_mult_out_v23[35], temp_mult_out_v23[32:16]};// v-cubed/4
			v2new = v2 + (((v2>>>2)-v23-(w2>>>1)+(c>>>2)-(v1_active>>>2))>>>4); //scale other vars to match v3
			w2new = w2 + (((v2>>>1)-(w2>>>1)) >>>9); // mult by a factor of 1/16
			//以下値の更新
			v1 = v1new ;
			w1 = w1new ;
			v2 = v2new ;
			w2 = w2new ;
		end
	end//クロックの処理終了
endmodule