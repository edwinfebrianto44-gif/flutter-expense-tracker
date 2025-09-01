"""Add attachment fields to transactions

Revision ID: 003_transaction_attachments
Revises: 002_enhanced_user_security
Create Date: 2024-01-15 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '003_transaction_attachments'
down_revision = '002_enhanced_user_security'
branch_labels = None
depends_on = None


def upgrade():
    """Add attachment fields to transactions table"""
    
    # Add new columns to transactions table
    op.add_column('transactions', sa.Column('attachment_url', sa.String(500), nullable=True))
    op.add_column('transactions', sa.Column('attachment_filename', sa.String(255), nullable=True))
    op.add_column('transactions', sa.Column('attachment_size', sa.Integer(), nullable=True))
    op.add_column('transactions', sa.Column('notes', sa.Text(), nullable=True))
    op.add_column('transactions', sa.Column('type', sa.String(20), nullable=True))
    op.add_column('transactions', sa.Column('updated_at', sa.DateTime(), nullable=True))


def downgrade():
    """Remove attachment fields from transactions table"""
    
    # Remove the added columns
    op.drop_column('transactions', 'updated_at')
    op.drop_column('transactions', 'type')
    op.drop_column('transactions', 'notes')
    op.drop_column('transactions', 'attachment_size')
    op.drop_column('transactions', 'attachment_filename')
    op.drop_column('transactions', 'attachment_url')
