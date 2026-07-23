from shared.database import Base, engine
import shared.models.db_models

print('creating tables')
Base.metadata.create_all(bind=engine)
print('tables created')
