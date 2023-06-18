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
                        w.valid,
                        w.regiao_estudo_id, 
                        w.media_declividade, 
                        w.praca_ou_parque, 
                        w.unidades_iluminacao, 
                        w.atividades_economicas, 
                        w.caminhabilidade
                    FROM walkable_grid w
                    WHERE regiao_estudo_id IS NOT NULL";

            using var command = new NpgsqlCommand(selectQuery, connection);
            using var reader = command.ExecuteReader();

            List<GridCell> grids = new();
            while (reader.Read())
            {
                GridCell grid = new()
                {
                    Id = reader.GetInt32(0),
                    Valid = reader.GetInt32(1),
                    RegiaoEstudoId = reader.GetInt32(2),
                    MediaDeclividade = reader.GetDouble(3),
                    PracaOuParque = reader.GetInt32(4) == 1,
                    UnidadesIluminacao = reader.IsDBNull(5) ? null : (int?)reader.GetInt32(5),
                    AtividadesEconomicas = reader.IsDBNull(6) ? null : (int?)reader.GetInt32(6),
                    Caminhabilidade = reader.IsDBNull(7) ? null : (double?)reader.GetDouble(7),
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

            using NpgsqlCommand command = new();
            command.Connection = connection;

            command.CommandText = @"
                UPDATE walkable_grid 
                    SET caminhabilidade = @caminhabilidade 
                    WHERE id = @id";
            command.Parameters.Add(new NpgsqlParameter("@caminhabilidade", NpgsqlTypes.NpgsqlDbType.Double));
            command.Parameters.Add(new NpgsqlParameter("@id", NpgsqlTypes.NpgsqlDbType.Integer));

            foreach (WalkabilityResult update in walkabilityResults)
            {
                command.Parameters["@caminhabilidade"].Value = update.Caminhabilidade;
                command.Parameters["@id"].Value = update.Id;
                command.ExecuteNonQuery();
            }
            return 0;
        }
    }

}
