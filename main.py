import pymysql
pymysql.install_as_MySQLdb()
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)


# Database configuration
#app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://adi:admin@mysql-service:3306/admin'
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('MYSQL_URI', 'mysql+pymysql://gaetan:admin@mysql-service:3306/admin') #user:password@database-service:port/databasename
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Task model
class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    done = db.Column(db.Boolean, default=False)

    def __repr__(self):
        return f"Task({self.title}, {self.description}, {self.done})"

# Create the database tables
with app.app_context():
    db.create_all()

# CREATE task
@app.route('/tasks', methods=['POST'])
def create_task():
    data = request.get_json()
    title = data.get('title')
    description = data.get('description')
    if not title:
        return jsonify({"message": "Title is required"}), 400
    new_task = Task(title=title, description=description)
    db.session.add(new_task)
    db.session.commit()
    return jsonify({"message": "Task created", "task": {"title": title, "description": description}}), 201

# READ all tasks
@app.route('/tasks', methods=['GET'])
def get_tasks():
    tasks = Task.query.all()
    task_list = [{"id": task.id, "title": task.title, "description": task.description, "done": task.done} for task in tasks]
    return jsonify({"tasks": task_list})

# READ single task
@app.route('/tasks/<int:task_id>', methods=['GET'])
def get_task(task_id):
    task = Task.query.get_or_404(task_id)
    return jsonify({"id": task.id, "title": task.title, "description": task.description, "done": task.done})

# UPDATE task
@app.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json()
    task.title = data.get('title', task.title)
    task.description = data.get('description', task.description)
    task.done = data.get('done', task.done)
    db.session.commit()
    return jsonify({"message": "Task updated",
                    "task": {"id": task.id, "title": task.title, "description": task.description, "done": task.done}})


# DELETE task
@app.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return jsonify({"message": "Task deleted"})


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
