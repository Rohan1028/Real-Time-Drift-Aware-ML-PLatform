from feast import Entity, ValueType

user = Entity(name="user", value_type=ValueType.STRING, description="Unique user identifier")
