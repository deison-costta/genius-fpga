// fsm_genius.v
// Mesma maquina de estados do fsm.bdf, escrita em Verilog so para o Quartus
// conseguir desenhar o diagrama (Tools > Netlist Viewers > State Machine Viewer).
// Estados, transicoes e saidas tirados do fsm.bdf (11 flip-flops, um por estado).
// Portas com os mesmos nomes do bloco fsm.

module fsm_genius (
    input  clk,
    input  rst_n,
    input  start,
    input  erro,
    input  fim_seq,
    input  fim_jogo,
    input  fim_tempo,
    input  press,
    input  fim_alinha,
    output gera,
    output ld,
    output led_en,
    output led_erro,
    output led_vit,
    output idle,
    output inc_passo,
    output zera_passo,
    output gira,
    output carrega,
    output ena,
    output inc_round
);

    parameter IDLE    = 4'd0,
              GERA    = 4'd1,
              ALINHA1 = 4'd2,
              MOSTRA  = 4'd3,
              PAUSA   = 4'd4,
              ALINHA2 = 4'd5,
              ESPERA  = 4'd6,
              COMPARA = 4'd7,
              SOLTA   = 4'd8,
              ERRO    = 4'd9,
              VITORIA = 4'd10;

    reg [3:0] estado;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            estado <= IDLE;
        else
            case (estado)
                IDLE:
                    if (start) estado <= GERA;
                GERA:
                    estado <= ALINHA1;
                ALINHA1:
                    if (fim_alinha) estado <= MOSTRA;
                MOSTRA:
                    if (fim_tempo) estado <= PAUSA;
                PAUSA:
                    if (fim_tempo && fim_seq) estado <= ALINHA2;
                    else if (fim_tempo && !fim_seq) estado <= MOSTRA;
                ALINHA2:
                    if (fim_alinha) estado <= ESPERA;
                ESPERA:
                    if (press) estado <= COMPARA;
                COMPARA:
                    if (erro) estado <= ERRO;
                    else if (!fim_seq) estado <= SOLTA;
                    else if (fim_seq && !fim_jogo) estado <= GERA;
                    else if (fim_seq && fim_jogo) estado <= VITORIA;
                SOLTA:
                    if (!press) estado <= ESPERA;
                ERRO:
                    if (start) estado <= IDLE;
                VITORIA:
                    if (start) estado <= IDLE;
                default:
                    estado <= IDLE;
            endcase
    end

    // saidas ligadas enquanto esta no estado
    assign idle     = (estado == IDLE);
    assign gera     = (estado == GERA);
    assign ld       = (estado == GERA);
    assign led_en   = (estado == MOSTRA);
    assign led_erro = (estado == ERRO);
    assign led_vit  = (estado == VITORIA);
    assign gira     = (estado == ALINHA1) || (estado == ALINHA2);

    // saidas que dependem tambem das entradas (ligam so no clock da transicao)
    assign carrega    = (estado == GERA) || ((estado == PAUSA) && fim_tempo && fim_seq);
    assign zera_passo = (estado == GERA) || ((estado == PAUSA) && fim_tempo && fim_seq);
    assign inc_passo  = ((estado == PAUSA) && fim_tempo) || ((estado == COMPARA) && !erro && !fim_seq);
    assign ena        = (estado == GERA)
                     || ((estado == ALINHA1) && !fim_alinha)
                     || ((estado == ALINHA2) && !fim_alinha)
                     || ((estado == PAUSA) && fim_tempo)
                     || ((estado == COMPARA) && !erro);
    assign inc_round  = ((estado == IDLE) && start)
                     || ((estado == COMPARA) && !erro && fim_seq && !fim_jogo);

endmodule
