namespace WalkabilityMetrics.Models
{
    public class GridCell
    {
        public int Id { get; set; }
        public int Valid { get; set; }
        public int RegiaoEstudoId { get; set; }
        public double MediaDeclividade { get; set; }
        public bool PracaOuParque { get; set; }
        public int? UnidadesIluminacao { get; set; }
        public int? AtividadesEconomicas { get; set; }
        public double? Caminhabilidade { get; set; }
    }
}
