using Dapper;
using Npgsql;
using WalkabilityMetrics.Models;

namespace WalkabilityMetrics.Repositories
{
    public class GeodataRepository : IGeodataRepository
    {
        private readonly string _connectionString;

        public GeodataRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public IEnumerable<GridCell> GetWalkableGrid()
        {
            using NpgsqlConnection connection = new(_connectionString);
            connection.Open();

            string selectQuery = @"
                    SELECT w.id,
		                w.media_declividade, 
		                w.praca_ou_parque, 
		                w.unidades_iluminacao, 
		                w.atividades_economicas,
		                w.meio_fio,
		                w.pavimentacao, 
		                w.class_viaria, 
		                w.caminhabilidade
	                FROM walkable_grid w";

            using var command = new NpgsqlCommand(selectQuery, connection);
            using var reader = command.ExecuteReader();

            List<GridCell> grids = new();
            while (reader.Read())
            {
                GridCell grid = new()
                {
                    Id = reader.GetInt32(0),
                    MediaDeclividade = reader.GetDouble(1),
                    PracaOuParque = reader.GetInt32(2) == 1,
                    UnidadesIluminacao = reader.IsDBNull(3) ? null : (int?)reader.GetInt32(3),
                    AtividadesEconomicas = reader.IsDBNull(4) ? null : (int?)reader.GetInt32(4),
                    MeioFio = reader.GetInt32(5) == 1,
                    Pavimentacao = reader.GetInt32(6) == 1,
                    ClassificacaoViaria = reader.IsDBNull(7) ? null : reader.GetString(7),
                    Caminhabilidade = reader.IsDBNull(8) ? null : (double?)reader.GetDouble(8),
                };

                grids.Add(grid);
            }

            connection.Close();
            return grids;
        }

        public int UpdateWalkabilityScore(IEnumerable<WalkabilityResult> walkabilityResults)
        {
            using NpgsqlConnection connection = new(_connectionString);
            connection.Open();

            string updateQuery = @"
                    UPDATE walkable_grid 
                    SET caminhabilidade = @Caminhabilidade 
                    WHERE id = @Id";

            return connection.Execute(updateQuery, walkabilityResults);
        }
    }
}