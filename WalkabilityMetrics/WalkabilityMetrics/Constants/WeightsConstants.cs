﻿namespace WalkabilityMetrics.Constants
{
    public static class WeightsConstants
    {
        public static readonly double PesoDeclividade = 0.45;
        public static readonly double PesoPracaOuParque = 0.1;
        public static readonly double PesoIluminacao = 0.15;
        public static readonly double PesoAtividadesEconomicas = 0.3;
        // A soma dos pesos acima deve sempre ser igual a 1.

        public static readonly int[] DeclividadeMarcos = { 0, 5, 10, 20, 40 };
        public static readonly double[] DeclividadePesos = { 1, 0.8, 0.6, 0.4, 0.2 };

    }
}
