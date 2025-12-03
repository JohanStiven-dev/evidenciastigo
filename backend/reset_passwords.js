require('dotenv').config();
const { User } = require('./src/models/init-associations');
const bcrypt = require('bcryptjs');

async function resetPasswords() {
    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('123456', salt);

        const users = ['comercial@tigo.com.co', 'productor@tigo.com.co', 'cliente@tigo.com.co', 'comercial2@tigo.com.co'];

        for (const email of users) {
            const [updated] = await User.update({ password: hashedPassword }, { where: { email } });
            if (updated) {
                console.log(`Password reset for ${email}`);
            } else {
                console.log(`User ${email} not found`);
            }
        }
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

resetPasswords();
