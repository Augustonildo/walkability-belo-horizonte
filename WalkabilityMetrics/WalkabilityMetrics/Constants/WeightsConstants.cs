﻿namespace WalkabilityMetrics.Constants
{
    public static class WeightsConstants
    {
        public static readonly double PesoDeclividade = 0.4;
        public static readonly int[] DeclividadeMarcos = { 0, 5, 10, 20, 40 };
        public static readonly double[] DeclividadePesos = { 1, 0.8, 0.6, 0.4, 0.2 };

        public static readonly double PesoPracaOuParque = 0.1;
        public static readonly double PesoIluminacao = 0.25;
        public static readonly double PesoAtividadesEconomicas = 0.25;
    }
}