using WalkabilityMetrics.Constants;
using WalkabilityMetrics.Models;
using WalkabilityMetrics.Repositories;

namespace WalkabilityMetrics
{
    static class Program
    {
        static void Main()
        {
            Console.WriteLine("Inicializando cálculo de caminhabilidade.");

            IGeodataRepository repository = new GeodataRepository(ConnectionConstants.connectionString);
            IEnumerable<GridCell> grid = repository.GetWalkableGrid();

            if (grid.Any())
            {
                IEnumerable<WalkabilityResult> walkabilityResults = EstimateWalkabilityMetrics(grid);
                repository.UpdateWalkabilityScore(walkabilityResults);
            }

            Console.WriteLine("Fim do cálculo.");
            Console.ReadLine();
        }

        static IEnumerable<WalkabilityResult> EstimateWalkabilityMetrics(IEnumerable<GridCell> grid)
        {
            List<WalkabilityResult> walkabilityResults = new();

            foreach (GridCell cell in grid)
            {
                double walkability = WeightBalanceWalkability(cell);
                walkabilityResults.Add(new WalkabilityResult { Id = cell.Id, Caminhabilidade = walkability });
            }

            return walkabilityResults;
        }

        static double WeightBalanceWalkability(GridCell cell)
        {
            return
                    WeightsConstants.PesoDeclividade * CalcularDeclividade(cell.MediaDeclividade) +
                    WeightsConstants.PesoPracaOuParque * CalcularPracaOuParque(cell.PracaOuParque) +
                    WeightsConstants.PesoIluminacao * CalcularIluminacao(cell.UnidadesIluminacao) +
                    WeightsConstants.PesoAtividadesEconomicas * CalcularAtividadesEconomicas(cell.AtividadesEconomicas);
        }

        static double CalcularDeclividade(double declividade)
        {
            for (int i = 0; i < WeightsConstants.DeclividadeMarcos.Length; i++)
            {
                // Cada um dos marcos de declividade está atrelado a um
                // peso para a nota, representado no mesmo index.
                if (declividade <= WeightsConstants.DeclividadeMarcos[i])
                    return WeightsConstants.DeclividadePesos[i];
            }

            // Se a declividade média da célula for superior do que todos os marcos, 
            // A nota de declividade para esta célula será 0.
            return 0;
        }

        static int CalcularPracaOuParque(bool pracaOuParque)
        {
            return pracaOuParque ? 1 : 0;
        }

        static double CalcularIluminacao(int? unidadesIluminacao)
        {
            if (unidadesIluminacao == null || unidadesIluminacao <= 0) return 0;
            if (unidadesIluminacao == 1) return 0.6;
            if (unidadesIluminacao == 2) return 0.9;
            return 1;
        }

        static double CalcularAtividadesEconomicas(int? atividadesEconomicas)
        {
            if (atividadesEconomicas == null || atividadesEconomicas <= 0) return 0;
            if (atividadesEconomicas == 1) return 0.5;
            if (atividadesEconomicas == 2) return 0.7;
            if (atividadesEconomicas == 3) return 0.8;
            return 1;
        }
    }
}
