const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./UserModel');

const RefreshToken = sequelize.define('RefreshToken', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
  },
  token: {
    type: DataTypes.STRING(500), // Store the refresh token string
    allowNull: false,
    unique: true,
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  revoked_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  replaced_by_token: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },
}, {
  tableName: 'RefreshTokens',
  timestamps: true,
});

RefreshToken.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(RefreshToken, { foreignKey: 'user_id' });

module.exports = RefreshToken;
