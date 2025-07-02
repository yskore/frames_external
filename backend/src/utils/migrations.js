const { migratePiecesFlagFields } = require('./flagMigration');

const runMigrations = async () => {
  console.log('Running database migrations...');
  
  try {
    const migrationResult = await migratePiecesFlagFields();
    console.log('Flag migration result:', migrationResult);
    
    console.log('All migrations completed successfully');
    return { success: true };
  } catch (error) {
    console.error('Error running migrations:', error);
    return { success: false, error: error.message };
  }
};

module.exports = { runMigrations };
